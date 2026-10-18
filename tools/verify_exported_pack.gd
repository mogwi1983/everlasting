extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "The Everlasting Delve", "exported identity")
	_check(FileAccess.file_exists("res://localization/en.json"), "English campaign catalog")
	var locale_service := root.get_node_or_null("I18n")
	_check(locale_service != null and String(locale_service.call("get_locale")) == "en", "English-only runtime locale")
	_check(root.get_node_or_null("CampaignStore") != null, "persistent campaign store registered")

	for hero: Dictionary in CampaignEngine.archetypes():
		var portrait_path := String(hero.get("portrait", ""))
		_check(ResourceLoader.exists(portrait_path), "hero portrait: " + portrait_path)
	for quest: Dictionary in CampaignEngine.QUESTS:
		var scene_path := String(quest.get("scene", ""))
		_check(ResourceLoader.exists(scene_path), "quest scene: " + scene_path)
	for path: String in [
		CampaignEngine.DM_PORTRAIT,
		CampaignEngine.MERCHANT_PORTRAIT,
		CampaignEngine.HOUND_PORTRAIT,
		"res://assets/share/favicon.png",
	]:
		_check(ResourceLoader.exists(path), "campaign visual: " + path)

	_check(not ResourceLoader.exists("res://test/test_suite.tscn"), "test scene excluded")
	_check(not ResourceLoader.exists("res://tools/capture_native.gd"), "native capture tool excluded")
	_check(not ResourceLoader.exists("res://autoload/global_leaderboard.gd"), "retired host adapter excluded")
	_check(not root.has_node("GlobalLeaderboard"), "no dormant network autoload")
	_check(not DirAccess.dir_exists_absolute("res://assets/template/generated"), "retired creative assets excluded")
	_check(not DirAccess.dir_exists_absolute("res://assets/template/audio"), "no default audio assets")

	var font := load("res://assets/template/fonts/ui_regular.tres") as Font
	_check(font != null, "exported UI font")
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://localization/en.json"))
	_check(catalog is Dictionary, "valid English campaign catalog")
	if font != null and catalog is Dictionary:
		for value_variant: Variant in catalog.values():
			var value := String(value_variant)
			for index: int in value.length():
				var codepoint := value.unicode_at(index)
				if codepoint >= 32:
					_check(font.has_char(codepoint), "exported English glyph: %d" % codepoint)

	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported campaign main scene")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		var content: Variant = main.get("_content")
		_check(content is VBoxContainer and content.get_child_count() > 0, "pack builds the title interface")
		_check(_contains_text(main, "The Everlasting Delve"), "pack title screen")
		_check(_contains_text(main, "Begin a new campaign"), "new campaign entry point")
		_check(main.has_method("_show_creation"), "hero creation entry point")
		_check(not main.has_method("_maybe_capture"), "capture routing removed from runtime")
		_check(not main.has_method("_open_tuning"), "release tuning entry point excluded")
		_check(not ResourceLoader.exists("res://scripts/ui/tuning_panel.gd"), "release tuning panel excluded")
		main.call("_show_creation")
		await process_frame
		await process_frame
		_check(_contains_text(main, "Choose your adventurer"), "pack opens hero creation")
		_check(_count_buttons_with_prefix(main, "Begin as ") == CampaignEngine.archetypes().size(), "all race-and-class choices are present")
		main.queue_free()
		await process_frame

	var audio := root.get_node_or_null("AudioDirector")
	_check(audio != null, "audio director registered")
	if audio != null:
		_check(not bool(audio.call("play_cue", "ui.confirm")), "pack missing SFX is silent")
		_check(not bool(audio.call("play_music", "music.gameplay")), "pack missing BGM is silent")
		audio.call("release_streams")

	if _failures.is_empty():
		print("[exported-pack] PASS: identity, campaign assets, fonts, English UI, hero creation, exclusions, silent audio")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)


func _contains_text(node: Node, expected: String) -> bool:
	if node is Label and String((node as Label).text).contains(expected):
		return true
	if node is Button and String((node as Button).text).contains(expected):
		return true
	for child: Node in node.get_children():
		if _contains_text(child, expected):
			return true
	return false


func _count_buttons_with_prefix(node: Node, prefix: String) -> int:
	var count := 0
	if node is Button and String((node as Button).text).begins_with(prefix):
		count += 1
	for child: Node in node.get_children():
		count += _count_buttons_with_prefix(child, prefix)
	return count


func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
