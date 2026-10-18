class_name CampaignEngine
extends RefCounted

const HEROES: Array[Dictionary] = [
	{
		"id": "human_fighter",
		"race": "Human",
		"role": "Fighter",
		"tagline": "The steadfast blade",
		"description": "A resilient front-line protector who meets danger without flinching.",
		"might": 3,
		"wit": 1,
		"heart": 2,
		"max_hp": 24,
		"portrait": "res://assets/campaign/portraits/human_fighter.png"
	},
	{
		"id": "elf_ranger",
		"race": "Elf",
		"role": "Ranger",
		"tagline": "The patient pathfinder",
		"description": "A keen tracker who reads the forest as easily as a well-worn map.",
		"might": 2,
		"wit": 3,
		"heart": 1,
		"max_hp": 20,
		"portrait": "res://assets/campaign/portraits/elf_ranger.png"
	},
	{
		"id": "dwarf_cleric",
		"race": "Dwarf",
		"role": "Cleric",
		"tagline": "The keeper of embers",
		"description": "A steady-hearted healer who finds courage in old promises and brighter things.",
		"might": 2,
		"wit": 1,
		"heart": 3,
		"max_hp": 22,
		"portrait": "res://assets/campaign/portraits/dwarf_cleric.png"
	},
	{
		"id": "halfling_rogue",
		"race": "Halfling",
		"role": "Rogue",
		"tagline": "The quick-footed spark",
		"description": "A nimble problem-solver who knows that a clever plan beats a locked door.",
		"might": 1,
		"wit": 3,
		"heart": 2,
		"max_hp": 19,
		"portrait": "res://assets/campaign/portraits/halfling_rogue.png"
	}
]

const QUESTS: Array[Dictionary] = [
	{
		"title": "The Lantern on the Old Road",
		"location": "Brackenford / The Old Lantern Road",
		"scene": "res://assets/campaign/scenes/old_road_shrine.png",
		"hook": "A roadside lantern has gone dark, and the wayfarers who depended on its light have begun to vanish."
	},
	{
		"title": "The Missing Waystone",
		"location": "Morrowfen / The Reedwater Crossing",
		"scene": "res://assets/campaign/scenes/morrowfen_reedwater.png",
		"hook": "A carved waystone has been taken from the marsh road; without it, travelers keep returning to the same bend."
	},
	{
		"title": "A Bell Beneath the Roots",
		"location": "Ashgrove / The Hollow Bell",
		"scene": "res://assets/campaign/scenes/ashgrove_hollow_bell.png",
		"hook": "A bell rings below the oldest tree at midnight, though no living hand has touched it in a century."
		},
	{
		"title": "The Warden's Lost Satchel",
		"location": "Rookridge / The Watcher's Steps",
		"scene": "res://assets/campaign/scenes/rookridge_watchers_steps.png",
		"hook": "A warden's satchel holds a map no one can remember drawing, and its last known owner has not returned."
	},
	{
		"title": "The Quiet Cairn",
		"location": "Northmere / The Moonlit Cairn",
		"scene": "res://assets/campaign/scenes/northmere_moonlit_cairn.png",
		"hook": "The stones of a hilltop cairn have shifted during the night, revealing a light that answers to no name."
	}
]

const SHOP_ITEMS: Array[Dictionary] = [
	{"id": "herbal_poultice", "name": "Herbal poultice", "price": 8, "description": "Restore up to 8 health when used."},
	{"id": "trail_rations", "name": "Trail rations", "price": 5, "description": "A filling meal for the long road."},
	{"id": "lantern_oil", "name": "Lantern oil", "price": 6, "description": "A small refill for a dark stretch of road."},
	{"id": "waystone_charm", "name": "Waystone charm", "price": 18, "description": "A warm bronze token said to steady a traveler."}
]

const LOOT_ITEMS: Array[Dictionary] = [
	{"id": "moon_silver_arrow", "name": "Moon-silver arrow", "description": "A bright arrowhead etched with a tiny crescent."},
	{"id": "hearthleaf", "name": "Hearthleaf bundle", "description": "Three fragrant leaves with a soothing green glow."},
	{"id": "old_road_token", "name": "Old-road token", "description": "A worn brass token stamped with a lantern."},
	{"id": "waystone_fragment", "name": "Waystone fragment", "description": "A smooth blue stone that feels warm in the palm."}
]

const QUEST_LENGTH := 3
const DM_PORTRAIT := "res://assets/campaign/portraits/dungeon_master.png"
const MERCHANT_PORTRAIT := "res://assets/campaign/encounters/wayfarer_merchant.png"
const HOUND_PORTRAIT := "res://assets/campaign/encounters/moss_hound.png"


static func archetypes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hero: Dictionary in HEROES:
		result.append(hero.duplicate(true))
	return result


static func shop_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in SHOP_ITEMS:
		result.append(item.duplicate(true))
	return result


static func new_campaign(archetype_id: String, requested_name: String) -> Dictionary:
	var archetype: Dictionary = {}
	for option: Dictionary in HEROES:
		if String(option.get("id", "")) == archetype_id:
			archetype = option.duplicate(true)
			break
	if archetype.is_empty():
		archetype = HEROES[0].duplicate(true)
	var clean_name := requested_name.strip_edges().substr(0, 24)
	if clean_name.is_empty():
		clean_name = "Wanderer"
	var quest := _quest_for_index(0)
	var hero := {
		"id": archetype["id"],
		"name": clean_name,
		"race": archetype["race"],
		"role": archetype["role"],
		"portrait": archetype["portrait"],
		"might": archetype["might"],
		"wit": archetype["wit"],
		"heart": archetype["heart"]
	}
	return {
		"schema_version": 1,
		"hero": hero,
		"level": 1,
		"xp": 0,
		"gold": 15,
		"hp": int(archetype["max_hp"]),
		"max_hp": int(archetype["max_hp"]),
		"inventory": [
			{"id": "wayfarer_lantern", "name": "Wayfarer's lantern", "quantity": 1, "description": "A dependable little light for the miles ahead."},
			{"id": "herbal_poultice", "name": "Herbal poultice", "quantity": 1, "description": "Restore up to 8 health when used."}
		],
		"quest_index": 0,
		"quest_step": 0,
		"quests_completed": 0,
		"actions_taken": 0,
		"seed": int(Time.get_unix_time_from_system()),
		"current_quest": quest["title"],
		"last_heading": "The lantern is dark",
		"last_narration": "Our tale begins on the Old Lantern Road, where rain beads on the stones and the dusk smells of pine and iron. The roadside shrine should be warm with a keeper's light. Instead, its lantern is cold. A silver track vanishes beneath the roots nearby, while a lone wayfarer waits under the broken arch. Somewhere in the trees, something answers the wind with a low, patient call. The choice of where to begin is yours.",
		"last_action": "",
		"scene_actor": "merchant",
		"created_at": int(Time.get_unix_time_from_system())
	}


static func current_quest(state: Dictionary) -> Dictionary:
	return _quest_for_index(int(state.get("quest_index", 0)))


static func current_quest_step_count() -> int:
	return QUEST_LENGTH


static func get_choices(state: Dictionary) -> Array[Dictionary]:
	var step := int(state.get("quest_step", 0))
	match step % QUEST_LENGTH:
		0:
			return [
				{"label": "Examine the lantern and the silver tracks", "kind": "investigate"},
				{"label": "Ask the wayfarer what happened", "kind": "talk"},
				{"label": "Follow the trail into the pines", "kind": "track"}
			]
		1:
			return [
				{"label": "Study the strange mark on the stone", "kind": "investigate"},
				{"label": "Offer the moss hound a healing herb", "kind": "help"},
				{"label": "Circle the ruins without being seen", "kind": "sneak"}
			]
		_:
			return [
				{"label": "Stand your ground against the guardian", "kind": "attack"},
				{"label": "Speak the old promise aloud", "kind": "talk"},
				{"label": "Search for another way through", "kind": "investigate"}
			]


static func resolve_action(state: Dictionary, action_text: String, selected_kind: String = "") -> Dictionary:
	var updated := state.duplicate(true)
	var clean_action := action_text.strip_edges().substr(0, 180)
	if clean_action.is_empty():
		return updated
	var is_freeform := selected_kind.is_empty()
	var kind := classify_action(clean_action) if is_freeform else selected_kind
	var hero: Dictionary = updated.get("hero", {})	
	var stat_name := _stat_for_kind(kind)
	var ability := int(hero.get(stat_name, 1))	
	var rng := RandomNumberGenerator.new()
	rng.seed = int(updated.get("seed", 1)) + int(updated.get("actions_taken", 0)) * 104729 + clean_action.hash()
	var roll := rng.randi_range(1, 20) + ability + floori(float(int(updated.get("level", 1))) / 2.0)
	var difficulty := 10 + mini(6, int(updated.get("level", 1)))
	var success := roll >= difficulty
	var xp_reward := 8
	var gold_reward := 0
	var actor := ""
	var heading := "A new turn"
	var item_message := ""
	var old_hp := int(updated.get("hp", 1))

	match kind:
		"rest":
			updated["hp"] = mini(int(updated.get("max_hp", 1)), old_hp + 7)
			xp_reward = 3
			heading = "A breath beneath the boughs"
			actor = "merchant"
		"attack":
			xp_reward = 14 if success else 7
			gold_reward = rng.randi_range(2, 7) if success else 0
			heading = "Steel in the twilight" if success else "A hard lesson"
			actor = "hound"
			if not success:
				updated["hp"] = maxi(1, old_hp - rng.randi_range(2, 4))
		"investigate":
			xp_reward = 13 if success else 6
			gold_reward = rng.randi_range(1, 5) if success else 0
			heading = "A careful discovery" if success else "The clue stays hidden"
			actor = "merchant"
		"talk":
			xp_reward = 12 if success else 6
			gold_reward = rng.randi_range(1, 4) if success else 0
			heading = "A promise shared" if success else "An answer held back"
			actor = "merchant"
		"track", "sneak":
			xp_reward = 13 if success else 7
			gold_reward = rng.randi_range(1, 5) if success else 0
			heading = "The trail opens" if success else "The woods turn against you"
			actor = "hound"
			if not success:
				updated["hp"] = maxi(1, old_hp - rng.randi_range(1, 3))
		"help":
			xp_reward = 15 if success else 8
			gold_reward = rng.randi_range(1, 5) if success else 0
			heading = "Kindness changes the path" if success else "A wary first step"
			actor = "hound"
		"loot":
			xp_reward = 10 if success else 4
			heading = "A hidden find" if success else "The cache is empty"
			actor = "merchant"
			if success:
				var loot_drop: Dictionary = LOOT_ITEMS[rng.randi_range(0, LOOT_ITEMS.size() - 1)].duplicate(true)
				add_item(updated, loot_drop)
				item_message = "You recover %s from the forgotten cache." % String(loot_drop.get("name", "a keepsake"))
			else:
				item_message = "You search the cache, but the niche is empty."
		"trade":
			xp_reward = 2
			heading = "A bargain on the road"
			actor = "merchant"
			var item_id := _item_mentioned(clean_action.to_lower())
			if not item_id.is_empty():
				var purchase := purchase_item(updated, item_id)
				if bool(purchase.get("ok", false)):
					updated = purchase["state"]
					item_message = String(purchase.get("message", ""))
				else:
					item_message = String(purchase.get("message", ""))
			else:
				item_message = "The wayfarer shows you a few useful wares. Open the shop to choose exactly what to buy."
		_:
			xp_reward = 9 if success else 6
			gold_reward = rng.randi_range(1, 3) if success else 0
			heading = "An unexpected turn" if success else "The world answers in its own way"
			actor = "merchant"

	if kind != "rest" and kind != "trade" and gold_reward > 0:
		updated["gold"] = int(updated.get("gold", 0)) + gold_reward
	updated["xp"] = int(updated.get("xp", 0)) + xp_reward
	updated["actions_taken"] = int(updated.get("actions_taken", 0)) + 1
	updated["quest_step"] = int(updated.get("quest_step", 0)) + 1
	updated["last_action"] = clean_action
	updated["last_heading"] = heading
	updated["scene_actor"] = actor

	var current := current_quest(updated)
	var narration := _action_narration(kind, success, clean_action, is_freeform, current, roll, difficulty, item_message)
	if gold_reward > 0:
		narration += " You also find %d gold along the way." % gold_reward
	if kind == "rest" and int(updated.get("hp", 0)) > old_hp:
		narration += " You recover %d health." % (int(updated["hp"]) - old_hp)
	if kind == "rest" and int(updated.get("hp", 0)) == old_hp:
		narration += " Your strength is already at its best."
	updated["last_narration"] = narration

	if success and kind in ["investigate", "attack", "track", "help"] and rng.randi_range(1, 100) <= 34:
		var loot: Dictionary = LOOT_ITEMS[rng.randi_range(0, LOOT_ITEMS.size() - 1)].duplicate(true)
		add_item(updated, loot)
		updated["last_narration"] += " Among the leaves you find %s." % String(loot.get("name", "a keepsake"))

	var level_message := _apply_level_ups(updated)
	if not level_message.is_empty():
		updated["last_narration"] += " " + level_message

	if int(updated.get("quest_step", 0)) >= QUEST_LENGTH:
		var completed := current_quest(updated)
		updated["quests_completed"] = int(updated.get("quests_completed", 0)) + 1
		updated["quest_index"] = int(updated.get("quest_index", 0)) + 1
		updated["quest_step"] = 0
		updated["xp"] = int(updated.get("xp", 0)) + 38
		updated["gold"] = int(updated.get("gold", 0)) + 12
		var reward: Dictionary = LOOT_ITEMS[int(updated["quests_completed"]) % LOOT_ITEMS.size()].duplicate(true)
		add_item(updated, reward)
		var next_quest := current_quest(updated)
		updated["current_quest"] = next_quest["title"]
		updated["last_heading"] = "A chapter closes, another opens"
		updated["scene_actor"] = "merchant"
		updated["last_narration"] += "\n\nYou complete %s. The wayfarer pays 12 gold and places %s in your hand. Then, just beyond the lantern's reach, a new trail appears: %s. %s" % [String(completed["title"]), String(reward["name"]), String(next_quest["title"]), String(next_quest["hook"])]
		var completion_level_message := _apply_level_ups(updated)
		if not completion_level_message.is_empty():
			updated["last_narration"] += " " + completion_level_message
	else:
		updated["current_quest"] = current["title"]

	if int(updated.get("hp", 1)) <= 0:
		updated["hp"] = 1
		updated["last_narration"] += " A companion draws you back from the brink. Your story is not over."
	updated["schema_version"] = 1
	return updated


static func purchase_item(state: Dictionary, item_id: String) -> Dictionary:
	var updated := state.duplicate(true)
	for item: Dictionary in SHOP_ITEMS:
		if String(item.get("id", "")) != item_id:
			continue
		var cost := int(item.get("price", 0))
		if int(updated.get("gold", 0)) < cost:
			return {"ok": false, "state": state.duplicate(true), "message": "You need %d gold to buy %s." % [cost, String(item.get("name", "that item"))]}
		updated["gold"] = int(updated.get("gold", 0)) - cost
		add_item(updated, {"id": item["id"], "name": item["name"], "quantity": 1, "description": item["description"]})
		return {"ok": true, "state": updated, "message": "You buy %s for %d gold." % [String(item["name"]), cost]}
	return {"ok": false, "state": state.duplicate(true), "message": "That item is no longer on the wayfarer's cart."}


static func use_item(state: Dictionary, item_id: String) -> Dictionary:
	var updated := state.duplicate(true)
	var inventory: Array = updated.get("inventory", [])
	for index: int in inventory.size():
		var item: Dictionary = inventory[index]
		if String(item.get("id", "")) != item_id:
			continue
		if item_id == "herbal_poultice":
			if int(updated.get("hp", 0)) >= int(updated.get("max_hp", 0)):
				return {"ok": false, "state": state.duplicate(true), "message": "You are already at full health."}
			var recovered := mini(8, int(updated.get("max_hp", 0)) - int(updated.get("hp", 0)))
			updated["hp"] = int(updated.get("hp", 0)) + recovered
			item["quantity"] = int(item.get("quantity", 1)) - 1
			if int(item["quantity"]) <= 0:
				inventory.remove_at(index)
			else:
				inventory[index] = item
			updated["inventory"] = inventory
			return {"ok": true, "state": updated, "message": "You use a poultice and recover %d health." % recovered}
		return {"ok": false, "state": state.duplicate(true), "message": "That item cannot be used right now."}
	return {"ok": false, "state": state.duplicate(true), "message": "You do not have that item."}


static func add_item(state: Dictionary, addition: Dictionary) -> void:
	var inventory: Array = state.get("inventory", [])
	var item_id := String(addition.get("id", ""))
	for index: int in inventory.size():
		var item: Dictionary = inventory[index]
		if String(item.get("id", "")) == item_id:
			item["quantity"] = int(item.get("quantity", 1)) + int(addition.get("quantity", 1))
			inventory[index] = item
			state["inventory"] = inventory
			return
	inventory.append(addition.duplicate(true))
	state["inventory"] = inventory


static func classify_action(action_text: String) -> String:
	var words := action_text.to_lower()
	if _contains_any(words, ["buy", "purchase", "barter", "trade", "shop"]):
		return "trade"
	if _contains_any(words, ["rest", "sleep", "camp", "recover", "take a break"]):
		return "rest"
	if _contains_any(words, ["help", "heal", "protect", "rescue", "comfort", "save", "share"]):
		return "help"
	if _contains_any(words, ["attack", "fight", "strike", "shoot", "slash", "cast", "defend", "confront", "charge"]):
		return "attack"
	if _contains_any(words, ["talk", "ask", "tell", "persuade", "negotiate", "bargain", "convince", "speak", "question"]):
		return "talk"
	if _contains_any(words, ["loot", "collect", "gather", "salvage", "pick up", "take"]):
		return "loot"
	if _contains_any(words, ["sneak", "hide", "creep", "track", "follow", "scout", "climb", "slip", "shadow"]):
		return "track"
	if _contains_any(words, ["search", "inspect", "examine", "investigate", "look", "study", "read", "check", "listen"]):
		return "investigate"
	return "improvise"


static func _quest_for_index(index: int) -> Dictionary:
	var quest: Dictionary = QUESTS[index % QUESTS.size()].duplicate(true)
	if index >= QUESTS.size():
		var cycle := int(index / QUESTS.size()) + 1
		quest["title"] = "%s / Chronicle %d" % [String(quest["title"]), cycle]
	return quest


static func _action_narration(kind: String, success: bool, action_text: String, is_freeform: bool, quest: Dictionary, roll: int, difficulty: int, item_message: String) -> String:
	var opening := ""
	if is_freeform:
		var quoted := action_text
		if quoted.length() > 100:
			quoted = quoted.substr(0, 97) + "..."
		opening = "You try an unlisted action: \"%s\". The Dungeon Master folds your idea into the scene. " % quoted
		if kind == "improvise":
			opening += "It does not fit any familiar path, so the world responds on its own terms. "
	else:
		opening = "The Dungeon Master considers your choice. "
	var result := ""
	match kind:
		"attack":
			result = "You meet the moss hound at the edge of the shrine. " + ("Your timing holds; it backs away from the lantern path." if success else "It lands a glancing blow before retreating into the ferns.")
		"investigate":
			result = "You examine the place where the road and roots meet. " + ("A faint blue mark emerges beneath the mud, pointing toward the old stones." if success else "Rainwater has blurred the most obvious trace, but a thread of silver remains.")
		"talk":
			result = "The wayfarer listens as the wind turns through the arch. " + ("A small detail in the answer reveals who passed this way and why." if success else "The traveler hesitates, then offers a wary nod and a half-finished clue.")
		"track", "sneak":
			result = "You pick out the trail where it bends between the dark pines. " + ("A second set of tracks turns toward the old stones." if success else "The trail doubles back through the mud; something moves ahead, but you are not badly hurt.")
		"help":
			result = "You choose patience over fear. " + ("The hound lowers its head, and a hidden path opens beside the shrine." if success else "The creature stays cautious, but it no longer treats you as an immediate threat.")
		"loot":
			result = item_message
		"rest":
			result = "You pause beneath the broken arch, letting the rain and the quiet settle around you."
		"trade":
			result = item_message
		_:
			result = "Your plan changes the rhythm of the moment. " + ("The lantern flickers in answer, and the way forward becomes clearer." if success else "The world gives you a different clue: a faint chime from somewhere beneath the stones.")
	result += "\n\n" + String(quest.get("hook", "A new trail waits beyond the next rise."))
	if roll < difficulty:
		result += "\n\nThe attempt is difficult, but the story keeps moving; another approach is still open."
	return opening + result


static func _stat_for_kind(kind: String) -> String:
	match kind:
		"attack":
			return "might"
		"talk", "help", "trade", "rest":
			return "heart"
		_:
			return "wit"


static func _apply_level_ups(state: Dictionary) -> String:
	var messages: Array[String] = []
	while int(state.get("xp", 0)) >= int(state.get("level", 1)) * 100:
		state["level"] = int(state.get("level", 1)) + 1
		state["max_hp"] = int(state.get("max_hp", 1)) + 3
		state["hp"] = int(state.get("max_hp", 1))
		messages.append("You reach level %d. Your health grows, and you feel ready for the next road." % int(state["level"]))
	return " ".join(messages)


static func _item_mentioned(action_text: String) -> String:
	if action_text.contains("poultice") or action_text.contains("healing"):
		return "herbal_poultice"
	if action_text.contains("ration") or action_text.contains("food"):
		return "trail_rations"
	if action_text.contains("oil"):
		return "lantern_oil"
	if action_text.contains("charm") or action_text.contains("waystone"):
		return "waystone_charm"
	return ""


static func _contains_any(text: String, options: Array[String]) -> bool:
	for option: String in options:
		if text.contains(option):
			return true
	return false
