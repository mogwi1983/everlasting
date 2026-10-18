extends Node

var _failures: Array[String] = []
var _checks := 0
var _saved_campaign_bytes: Variant = null
var _saved_campaign_state: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_saved_campaign_bytes = FileAccess.get_file_as_bytes(CampaignStore.SAVE_PATH) if FileAccess.file_exists(CampaignStore.SAVE_PATH) else null
	_saved_campaign_state = CampaignStore.get_campaign()
	_clear_campaign_fixture()
	_test_language()
	_test_character_options()
	_test_custom_action_adaptation()
	_test_campaign_progression()
	_test_inventory_and_persistence()
	await _test_playable_scene()
	_restore_campaign_fixture()
	if _failures.is_empty():
		print("[campaign-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("[campaign-tests] " + failure)
	print("[campaign-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _clear_campaign_fixture() -> void:
	CampaignStore.set("_campaign", {})
	if FileAccess.file_exists(CampaignStore.SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(CampaignStore.SAVE_PATH))
		_expect(remove_error == OK, "temporary campaign fixture must start clean")


func _restore_campaign_fixture() -> void:
	if _saved_campaign_bytes == null:
		if FileAccess.file_exists(CampaignStore.SAVE_PATH):
			var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(CampaignStore.SAVE_PATH))
			_expect(remove_error == OK, "temporary campaign fixture must be removed")
	else:
		var file := FileAccess.open(CampaignStore.SAVE_PATH, FileAccess.WRITE)
		_expect(file != null, "original campaign save must be restorable")
		if file != null:
			file.store_buffer(_saved_campaign_bytes)
			file.close()
			_expect(FileAccess.get_file_as_bytes(CampaignStore.SAVE_PATH) == _saved_campaign_bytes, "original campaign save must be restored byte-for-byte")
	CampaignStore.set("_campaign", _saved_campaign_state.duplicate(true))


func _test_language() -> void:
	var i18n: Node = get_tree().root.get_node_or_null("I18n")
	_expect(i18n != null, "English localization service must be installed")
	if i18n == null:
		return
	_expect(String(i18n.call("get_locale")) == "en", "campaign content must start in English")
	i18n.call("set_locale", "zh-CN")
	_expect(String(i18n.call("get_locale")) == "en", "unsupported locale choices must remain pinned to English")
	_expect(String(i18n.call("t", "game.title")) == "The Everlasting Delve", "the English title must resolve from the catalog")


func _test_character_options() -> void:
	var options := CampaignEngine.archetypes()
	_expect(options.size() >= 4, "character creation must offer several race-and-class combinations")
	var seen_ids: Dictionary = {}
	for option: Dictionary in options:
		var option_id := String(option.get("id", ""))
		_expect(not option_id.is_empty() and not seen_ids.has(option_id), "each character option needs a unique identity")
		seen_ids[option_id] = true
		_expect(ResourceLoader.exists(String(option.get("portrait", ""))), "each character option must resolve its portrait: " + option_id)
	var hero_state := CampaignEngine.new_campaign("elf_ranger", "Eira")
	var hero: Dictionary = hero_state.get("hero", {})
	_expect(String(hero.get("race", "")) == "Elf" and String(hero.get("role", "")) == "Ranger", "the chosen race and class must shape the saved hero")
	_expect(int(hero_state.get("hp", 0)) == int(hero_state.get("max_hp", -1)), "new heroes must begin at full health")
	_expect(String(hero_state.get("current_quest", "")).length() > 0, "a new hero must enter the preselected adventure")


func _test_custom_action_adaptation() -> void:
	var state := CampaignEngine.new_campaign("halfling_rogue", "Pip")
	var custom_action := "I quietly follow the silver tracks between the pine roots."
	var updated := CampaignEngine.resolve_action(state, custom_action)
	_expect(String(updated.get("last_action", "")) == custom_action, "a unique player-written action must be retained")
	_expect(String(updated.get("last_narration", "")).contains(custom_action), "the Dungeon Master response must acknowledge the exact custom action")
	_expect(String(updated.get("last_narration", "")).contains("trail"), "the action's tracking intent must alter the contextual response")
	_expect(int(updated.get("actions_taken", 0)) == 1 and int(updated.get("quest_step", 0)) == 1, "a custom action must advance the ongoing story")
	var final_choices_state := state.duplicate(true)
	final_choices_state["quest_step"] = 2
	var choices := CampaignEngine.get_choices(final_choices_state)
	_expect(choices.size() >= 3, "the Dungeon Master must offer multiple contextual actions")
	_expect(String(choices[0].get("kind", "")) == "attack", "the guardian choice must resolve through the combat rules")


func _test_campaign_progression() -> void:
	var state := CampaignEngine.new_campaign("human_fighter", "Rowan")
	var quest_count := CampaignEngine.QUESTS.size()
	for _action_index: int in CampaignEngine.QUEST_LENGTH * quest_count + 3:
		state = CampaignEngine.resolve_action(state, "Rest beneath the old arch", "rest")
	_expect(int(state.get("quest_index", 0)) > quest_count, "quest progression must continue past the initial adventure cycle")
	_expect(CampaignEngine.current_quest(state).get("title", "").contains("Chronicle 2"), "the campaign must roll into a new chronicle instead of ending")
	_expect(int(state.get("quests_completed", 0)) >= quest_count, "completed quests must remain counted across campaign cycles")
	_expect(int(state.get("xp", 0)) > 0 and int(state.get("level", 1)) > 1, "actions and completed quests must grant experience and levels")
	_expect(not String(state.get("last_narration", "")).contains("Game Over"), "the ongoing campaign must not present a fixed ending")


func _test_inventory_and_persistence() -> void:
	_expect(CampaignEngine.classify_action("I loot the hidden cache") == "loot", "custom loot actions must be recognized")
	var looted_state: Dictionary = {}
	var looted_item_id := ""
	for seed_value: int in range(1, 121):
		var candidate := CampaignEngine.new_campaign("dwarf_cleric", "Mira")
		candidate["seed"] = seed_value
		candidate = CampaignEngine.resolve_action(candidate, "I loot the hidden cache")
		if not String(candidate.get("last_narration", "")).contains("from the forgotten cache."):
			continue
		looted_state = candidate
		for loot_item: Dictionary in CampaignEngine.LOOT_ITEMS:
			var candidate_id := String(loot_item.get("id", ""))
			if _inventory_has(looted_state.get("inventory", []), candidate_id):
				looted_item_id = candidate_id
				break
		break
	_expect(not looted_state.is_empty() and not looted_item_id.is_empty(), "a successful loot action must add a found item")
	if not looted_state.is_empty() and not looted_item_id.is_empty():
		_expect(CampaignStore.save_campaign(looted_state), "a looted campaign must be saveable")
		var looted_reload := CampaignStore.reload_campaign()
		_expect(_inventory_has(looted_reload.get("inventory", []), looted_item_id), "looted items must persist across a save and reload")
	var state := CampaignEngine.new_campaign("dwarf_cleric", "Mira")
	var purchase := CampaignEngine.purchase_item(state, "lantern_oil")
	_expect(bool(purchase.get("ok", false)), "the traveling shop must sell a purchasable item")
	if not bool(purchase.get("ok", false)):
		return
	var purchased: Dictionary = purchase.get("state", {})
	_expect(int(purchased.get("gold", -1)) == 9, "purchases must deduct their listed price")
	var inventory: Array = purchased.get("inventory", [])
	_expect(_inventory_has(inventory, "lantern_oil"), "bought items must enter the persistent inventory")
	_expect(CampaignStore.save_campaign(purchased), "the campaign store must accept a valid save")
	var reloaded := CampaignStore.reload_campaign()
	_expect(String(reloaded.get("hero", {}).get("name", "")) == "Mira", "hero identity must survive a reload")
	_expect(_inventory_has(reloaded.get("inventory", []), "lantern_oil"), "bought gear must survive a reload")
	_expect(int(reloaded.get("gold", -1)) == 9, "currency must survive a reload")
	var hurt_state := reloaded.duplicate(true)
	hurt_state["hp"] = int(hurt_state.get("max_hp", 0)) - 3
	var healing := CampaignEngine.use_item(hurt_state, "herbal_poultice")
	_expect(bool(healing.get("ok", false)), "a carried healing item must be usable")
	_expect(int(healing.get("state", {}).get("hp", 0)) == int(hurt_state.get("max_hp", 0)), "healing must restore health without exceeding its maximum")
	_expect(not _inventory_has(healing.get("state", {}).get("inventory", []), "herbal_poultice"), "a consumed healing item must leave the inventory")
	var failed_purchase := CampaignEngine.purchase_item(CampaignEngine.new_campaign("elf_ranger", "Low Purse"), "waystone_charm")
	_expect(not bool(failed_purchase.get("ok", false)), "the shop must reject purchases the player cannot afford")


func _test_playable_scene() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	_expect(packed != null, "the game scene must load")
	if packed == null:
		return
	var instance := packed.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(instance is Control, "the game must present its 2D campaign interface")
	instance.call("_show_creation")
	await get_tree().process_frame
	_expect(is_instance_valid(instance.get("_hero_name_input")), "character creation must collect a player-chosen name")
	instance.get("_hero_name_input").text = "Lyra"
	instance.call("_create_campaign", "elf_ranger")
	await get_tree().process_frame
	_expect(CampaignStore.has_campaign(), "starting a character must create a campaign")
	_expect(String(CampaignStore.get_campaign().get("hero", {}).get("name", "")) == "Lyra", "the selected name must reach the saved campaign")
	var action_input: LineEdit = instance.get("_custom_action_input")
	_expect(action_input != null, "the campaign screen must allow a custom action")
	if action_input != null:
		action_input.text = "I ask the wayfarer about the silver mark."
		instance.call("_submit_custom_action")
		await get_tree().process_frame
		_expect(String(CampaignStore.get_campaign().get("last_action", "")).contains("ask the wayfarer"), "the player-written action must be processed through the live interface")
	var persisted_before_shop := CampaignStore.get_campaign()
	instance.call("_buy_item", "lantern_oil")
	await get_tree().process_frame
	_expect(_inventory_has(CampaignStore.get_campaign().get("inventory", []), "lantern_oil"), "the live shop must save newly purchased gear")
	_expect(CampaignStore.get_campaign().get("gold", 0) < persisted_before_shop.get("gold", 0), "the live shop must spend persistent gold")
	instance.queue_free()
	await get_tree().process_frame


func _inventory_has(inventory: Array, item_id: String) -> bool:
	for item_variant: Variant in inventory:
		if item_variant is Dictionary and String(item_variant.get("id", "")) == item_id:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
