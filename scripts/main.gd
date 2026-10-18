extends Control

const BG_PATH := "res://assets/campaign/scenes/old_road_shrine.png"
const DM_PATH := "res://assets/campaign/portraits/dungeon_master.png"
const ICON_PATH := "res://assets/share/favicon.png"
const MERCHANT_PORTRAIT := "res://assets/campaign/encounters/wayfarer_merchant.png"
const HOUND_PORTRAIT := "res://assets/campaign/encounters/moss_hound.png"
const HERO_PANEL := Color(0.035, 0.061, 0.049, 0.94)
const STORY_PANEL := Color(0.045, 0.071, 0.056, 0.95)
const CARD_PANEL := Color(0.075, 0.102, 0.079, 0.96)
const TEXT_MAIN := Color(0.93, 0.88, 0.77)
const TEXT_MUTED := Color(0.69, 0.68, 0.59)
const GOLD := Color(0.86, 0.68, 0.36)
const RED := Color(0.71, 0.34, 0.27)

var _content: VBoxContainer
var _background: TextureRect
var _modal_layer: Control
var _hero_name_input: LineEdit
var _custom_action_input: LineEdit
var _story_feedback := ""
var _shop_message := ""
var _pending_hero_id := ""
var _body_font: Font
var _heading_font: Font
var _title_font: Font


func _ready() -> void:
	_body_font = load("res://assets/template/fonts/ui_regular.tres") as Font
	_heading_font = load("res://assets/template/fonts/display/generic_heading.tres") as Font
	_title_font = load("res://assets/template/fonts/display/generic_title.tres") as Font
	_build_shell()
	_show_title()


func _build_shell() -> void:
	var background := TextureRect.new()
	background.texture = load(BG_PATH) as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background = background
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.018, 0.031, 0.025, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)


func _show_title() -> void:
	_close_shop()
	_clear_content()
	_set_background(BG_PATH)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(center)

	var card := _panel(HERO_PANEL, GOLD, 24, 1, 32)
	card.custom_minimum_size = Vector2(590, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(stack)

	var icon := TextureRect.new()
	icon.texture = load(ICON_PATH) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(84, 84)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(icon)

	stack.add_child(_label(_t("game.title"), 35, TEXT_MAIN, true, true))
	stack.add_child(_label(_t("game.tagline"), 19, GOLD, true))
	stack.add_child(_label(_t("game.summary"), 16, TEXT_MUTED, false, true))

	if CampaignStore.has_campaign():
		var continue_button := _button(_t("home.continue"), true, 54)
		continue_button.pressed.connect(_continue_campaign)
		stack.add_child(continue_button)
		stack.add_child(_label(_t("home.continue_note"), 13, TEXT_MUTED, false, true))

	var new_button := _button(_t("home.new"), not CampaignStore.has_campaign(), 50)
	new_button.pressed.connect(_show_creation)
	stack.add_child(new_button)
	stack.add_child(_label(_t("home.save_note"), 12, TEXT_MUTED, false, true))


func _show_creation() -> void:
	_close_shop()
	_clear_content()
	var top := HBoxContainer.new()
	var back := _button(_t("hero.back"), false, 40)
	back.custom_minimum_size.x = 150
	back.pressed.connect(_show_title)
	top.add_child(back)
	top.add_child(_label(_t("hero.choose_title"), 28, TEXT_MAIN, true, true))
	_content.add_child(top)
	_content.add_child(_label(_t("hero.choose_subtitle"), 15, TEXT_MUTED, false, true))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	name_row.add_child(_label(_t("hero.name_label"), 15, GOLD, true))
	_hero_name_input = _line_edit(_t("hero.name_placeholder"))
	_hero_name_input.max_length = 24
	_hero_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_hero_name_input)
	_content.add_child(name_row)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(cards)

	for hero: Dictionary in CampaignEngine.archetypes():
		cards.add_child(_hero_card(hero))


func _hero_card(hero: Dictionary) -> PanelContainer:
	var card := _panel(CARD_PANEL, Color(0.36, 0.34, 0.25), 18, 1, 13)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	card.add_child(stack)

	var portrait := _portrait(String(hero.get("portrait", "")), Vector2(132, 128))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(portrait)
	stack.add_child(_label("%s %s" % [String(hero.get("race", "")), String(hero.get("role", ""))], 19, TEXT_MAIN, true, true))
	stack.add_child(_label(String(hero.get("tagline", "")), 13, GOLD, true, true))
	var description := _label(String(hero.get("description", "")), 13, TEXT_MUTED, false, true)
	description.custom_minimum_size.y = 44
	stack.add_child(description)
	var stats := "%s %d   %s %d   %s %d" % [
		_t("hero.might"), int(hero.get("might", 0)),
		_t("hero.wit"), int(hero.get("wit", 0)),
		_t("hero.heart"), int(hero.get("heart", 0))
	]
	stack.add_child(_label(stats, 12, TEXT_MUTED, true, true))
	var choose := _button(_t("hero.begin", {"race": hero.get("race", ""), "role": hero.get("role", "")}), true, 46)
	choose.pressed.connect(_request_new_campaign.bind(String(hero.get("id", ""))))
	stack.add_child(choose)
	return card


func _request_new_campaign(hero_id: String) -> void:
	_pending_hero_id = hero_id
	if not CampaignStore.has_campaign():
		_create_campaign(hero_id)
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = _t("home.replace_title")
	dialog.dialog_text = _t("home.replace_body")
	dialog.get_ok_button().text = _t("home.replace_ok")
	dialog.add_cancel_button(_t("home.replace_cancel"))
	dialog.confirmed.connect(_confirm_new_campaign)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 240))


func _confirm_new_campaign() -> void:
	_create_campaign(_pending_hero_id)


func _create_campaign(hero_id: String) -> void:
	var requested_name := ""
	if is_instance_valid(_hero_name_input):
		requested_name = _hero_name_input.text
	var campaign := CampaignEngine.new_campaign(hero_id, requested_name)
	if CampaignStore.save_campaign(campaign):
		_story_feedback = ""
		_show_campaign()


func _continue_campaign() -> void:
	if CampaignStore.has_campaign():
		_story_feedback = ""
		_show_campaign()


func _show_campaign() -> void:
	_close_shop()
	_clear_content()
	var state := CampaignStore.get_campaign()
	if state.is_empty():
		_show_title()
		return
	var current_quest := CampaignEngine.current_quest(state)
	_set_background(String(current_quest.get("scene", BG_PATH)))

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	var title_stack := VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", 2)
	title_stack.add_child(_label(_t("campaign.title"), 24, TEXT_MAIN, true, true))
	title_stack.add_child(_label(_t("campaign.tagline"), 12, GOLD, false, true))
	header.add_child(title_stack)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	header.add_child(_label(_t("campaign.saved"), 12, TEXT_MUTED, false, true))
	var return_button := _button(_t("campaign.return"), false, 40)
	return_button.custom_minimum_size.x = 154
	return_button.pressed.connect(_show_title)
	header.add_child(return_button)
	_content.add_child(header)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(columns)
	columns.add_child(_hero_sidebar(state))
	columns.add_child(_story_panel(state))


func _hero_sidebar(state: Dictionary) -> PanelContainer:
	var panel := _panel(HERO_PANEL, Color(0.39, 0.33, 0.23), 18, 1, 14)
	panel.custom_minimum_size.x = 270
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)

	var hero: Dictionary = state.get("hero", {})
	var portrait := _portrait(String(hero.get("portrait", "")), Vector2(130, 124))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(portrait)
	stack.add_child(_label(String(hero.get("name", "Wanderer")), 21, TEXT_MAIN, true, true))
	stack.add_child(_label(_t("campaign.level", {"level": state.get("level", 1), "race": hero.get("race", ""), "role": hero.get("role", "")}), 13, GOLD, true, true))

	var xp := int(state.get("xp", 0))
	var level := int(state.get("level", 1))
	var threshold := maxi(100, level * 100)
	var xp_bar := _progress_bar(Color(0.75, 0.57, 0.30))
	xp_bar.max_value = threshold
	xp_bar.value = xp % threshold
	stack.add_child(xp_bar)
	stack.add_child(_label(_t("campaign.experience", {"xp": xp}), 12, TEXT_MUTED, false, true))

	var hp := int(state.get("hp", 1))
	var max_hp := int(state.get("max_hp", 1))
	var hp_bar := _progress_bar(RED)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	stack.add_child(hp_bar)
	stack.add_child(_label(_t("campaign.health", {"hp": hp, "max_hp": max_hp}), 12, TEXT_MUTED, false, true))
	stack.add_child(_label(_t("campaign.gold", {"gold": state.get("gold", 0)}), 14, GOLD, true, true))
	stack.add_child(_hairline())
	stack.add_child(_label(_t("campaign.active_quest"), 11, GOLD, true))
	stack.add_child(_label(String(state.get("current_quest", "The Lantern on the Old Road")), 15, TEXT_MAIN, true, true))
	var quest_step := int(state.get("quest_step", 0)) + 1
	stack.add_child(_label(_t("campaign.quest_step", {"step": quest_step, "total": CampaignEngine.current_quest_step_count()}), 11, TEXT_MUTED, false, true))
	stack.add_child(_label(_t("campaign.quests_completed", {"count": state.get("quests_completed", 0)}), 11, TEXT_MUTED, false, true))
	stack.add_child(_hairline())
	stack.add_child(_label(_t("campaign.inventory"), 11, GOLD, true))
	var inventory: Array = state.get("inventory", [])
	if inventory.is_empty():
		stack.add_child(_label(_t("campaign.empty_inventory"), 12, TEXT_MUTED, false, true))
	else:
		for item_variant: Variant in inventory:
			var item: Dictionary = item_variant
			var quantity := int(item.get("quantity", 1))
			stack.add_child(_label("%s  x%d" % [String(item.get("name", "Item")), quantity], 12, TEXT_MAIN, false, true))
			if String(item.get("id", "")) == "herbal_poultice":
				var use_button := _button(_t("campaign.use_poultice"), false, 36)
				use_button.pressed.connect(_use_poultice)
				stack.add_child(use_button)
	var shop_button := _button(_t("campaign.shop"), true, 42)
	shop_button.pressed.connect(_show_shop)
	stack.add_child(shop_button)
	return panel


func _story_panel(state: Dictionary) -> PanelContainer:
	var panel := _panel(STORY_PANEL, Color(0.45, 0.38, 0.26), 20, 1, 18)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(stack)

	var quest := CampaignEngine.current_quest(state)
	var scene_header := HBoxContainer.new()
	scene_header.add_child(_label(_t("campaign.location"), 10, GOLD, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_header.add_child(spacer)
	scene_header.add_child(_label(String(quest.get("location", "The Old Lantern Road")), 12, TEXT_MUTED, false, true))
	stack.add_child(scene_header)

	var narrator_row := HBoxContainer.new()
	narrator_row.add_theme_constant_override("separation", 12)
	var dm := _portrait(DM_PATH, Vector2(70, 72))
	narrator_row.add_child(dm)
	var narration_column := VBoxContainer.new()
	narration_column.add_theme_constant_override("separation", 6)
	narration_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narration_column.add_child(_label(_t("campaign.dungeon_master"), 14, GOLD, true, true))
	var heading := String(state.get("last_heading", "The lantern is dark"))
	narration_column.add_child(_label(heading, 21, TEXT_MAIN, true, true))
	var narration := RichTextLabel.new()
	narration.bbcode_enabled = false
	narration.text = String(state.get("last_narration", ""))
	narration.fit_content = true
	narration.scroll_active = true
	narration.custom_minimum_size.y = 212
	narration.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narration.add_theme_color_override("default_color", TEXT_MAIN)
	narration.add_theme_font_override("normal_font", _body_font)
	narration.add_theme_font_size_override("normal_font_size", 15)
	narration_column.add_child(narration)
	narrator_row.add_child(narration_column)

	var actor := _actor_info(String(state.get("scene_actor", "merchant")))
	var actor_column := VBoxContainer.new()
	actor_column.add_theme_constant_override("separation", 5)
	actor_column.custom_minimum_size.x = 122
	actor_column.add_child(_label(_t("campaign.scene_actor"), 10, TEXT_MUTED, true, true))
	actor_column.add_child(_portrait(String(actor.get("portrait", MERCHANT_PORTRAIT)), Vector2(112, 104)))
	actor_column.add_child(_label(String(actor.get("name", "Wayfarer")), 11, GOLD, true, true))
	narrator_row.add_child(actor_column)
	stack.add_child(narrator_row)

	stack.add_child(_hairline())
	stack.add_child(_label(_t("campaign.custom_help"), 12, TEXT_MUTED, false, true))
	for choice: Dictionary in CampaignEngine.get_choices(state):
		var option := _button(String(choice.get("label", "Choose")), false, 42)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.pressed.connect(_take_choice.bind(choice))
		stack.add_child(option)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 9)
	_custom_action_input = _line_edit(_t("actions.custom_placeholder"))
	_custom_action_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_custom_action_input.max_length = 180
	_custom_action_input.text_submitted.connect(_on_custom_text_submitted)
	action_row.add_child(_custom_action_input)
	var send := _button(_t("actions.send"), true, 44)
	send.custom_minimum_size.x = 116
	send.pressed.connect(_submit_custom_action)
	action_row.add_child(send)
	stack.add_child(action_row)
	if not _story_feedback.is_empty():
		stack.add_child(_label(_story_feedback, 12, RED, true, true))
	return panel


func _take_choice(choice: Dictionary) -> void:
	var state := CampaignStore.get_campaign()
	var next := CampaignEngine.resolve_action(state, String(choice.get("label", "")), String(choice.get("kind", "")))
	_story_feedback = ""
	if CampaignStore.save_campaign(next):
		_show_campaign()


func _submit_custom_action() -> void:
	if not is_instance_valid(_custom_action_input):
		return
	var action_text := _custom_action_input.text.strip_edges()
	if action_text.is_empty():
		_story_feedback = _t("actions.empty")
		_show_campaign()
		return
	var next := CampaignEngine.resolve_action(CampaignStore.get_campaign(), action_text)
	_story_feedback = ""
	if CampaignStore.save_campaign(next):
		_show_campaign()


func _on_custom_text_submitted(_submitted: String) -> void:
	_submit_custom_action()


func _use_poultice() -> void:
	var result := CampaignEngine.use_item(CampaignStore.get_campaign(), "herbal_poultice")
	_story_feedback = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		CampaignStore.save_campaign(result["state"])
	_show_campaign()


func _show_shop() -> void:
	_close_shop()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 20
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_modal_layer = overlay
	var veil := ColorRect.new()
	veil.color = Color(0.008, 0.014, 0.011, 0.75)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card := _panel(HERO_PANEL, GOLD, 22, 1, 24)
	card.custom_minimum_size = Vector2(540, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	card.add_child(stack)
	var state := CampaignStore.get_campaign()
	stack.add_child(_label(_t("shop.title"), 27, TEXT_MAIN, true, true))
	stack.add_child(_label(_t("shop.wallet", {"gold": state.get("gold", 0)}), 14, GOLD, false, true))
	if not _shop_message.is_empty():
		stack.add_child(_label(_shop_message, 13, TEXT_MUTED, false, true))
	for item: Dictionary in CampaignEngine.shop_items():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var detail := VBoxContainer.new()
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail.add_child(_label(String(item.get("name", "Item")), 15, TEXT_MAIN, true, true))
		detail.add_child(_label(String(item.get("description", "")), 11, TEXT_MUTED, false, true))
		row.add_child(detail)
		var buy := _button(_t("shop.buy", {"price": item.get("price", 0)}), true, 42)
		buy.custom_minimum_size.x = 148
		buy.pressed.connect(_buy_item.bind(String(item.get("id", ""))))
		row.add_child(buy)
		stack.add_child(row)
	var close := _button(_t("shop.close"), false, 44)
	close.pressed.connect(_close_shop)
	stack.add_child(close)


func _buy_item(item_id: String) -> void:
	var result := CampaignEngine.purchase_item(CampaignStore.get_campaign(), item_id)
	_shop_message = String(result.get("message", ""))
	if bool(result.get("ok", false)):
		CampaignStore.save_campaign(result["state"])
		_story_feedback = ""
		_show_campaign()
	_show_shop()


func _close_shop() -> void:
	if is_instance_valid(_modal_layer):
		_modal_layer.queue_free()
		_modal_layer = null


func _actor_info(actor_id: String) -> Dictionary:
	if actor_id == "hound":
		return {"name": "Moss hound", "portrait": HOUND_PORTRAIT}
	return {"name": "Wayfarer", "portrait": MERCHANT_PORTRAIT}


func _set_background(resource_path: String) -> void:
	if not is_instance_valid(_background):
		return
	var texture := load(resource_path) as Texture2D
	if texture != null:
		_background.texture = texture


func _portrait(resource_path: String, size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load(resource_path) as Texture2D
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size = size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _panel(background: Color, border: Color, radius: int, border_width: int, margin: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button(text_value: String, primary: bool, min_height: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = min_height
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", _body_font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", TEXT_MAIN if not primary else Color(0.11, 0.12, 0.08))
	button.add_theme_color_override("font_hover_color", TEXT_MAIN if not primary else Color(0.11, 0.12, 0.08))
	button.add_theme_color_override("font_pressed_color", TEXT_MAIN if not primary else Color(0.11, 0.12, 0.08))
	var normal := StyleBoxFlat.new()
	normal.bg_color = GOLD if primary else Color(0.13, 0.17, 0.13, 0.95)
	normal.border_color = Color(0.87, 0.73, 0.47, 0.7)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 11
	normal.corner_radius_top_right = 11
	normal.corner_radius_bottom_left = 11
	normal.corner_radius_bottom_right = 11
	normal.content_margin_left = 11
	normal.content_margin_right = 11
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.92, 0.75, 0.43) if primary else Color(0.18, 0.23, 0.17, 1)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.72, 0.55, 0.29) if primary else Color(0.10, 0.14, 0.11, 1)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = Color(1.0, 0.84, 0.52, 1)
	focus.border_width_left = 2
	focus.border_width_top = 2
	focus.border_width_right = 2
	focus.border_width_bottom = 2
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	return button


func _line_edit(placeholder: String) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.custom_minimum_size.y = 42
	field.add_theme_font_override("font", _body_font)
	field.add_theme_font_size_override("font_size", 14)
	field.add_theme_color_override("font_color", TEXT_MAIN)
	field.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.078, 0.064, 0.98)
	style.border_color = Color(0.47, 0.43, 0.31, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	field.add_theme_stylebox_override("normal", style)
	field.add_theme_stylebox_override("focus", style.duplicate())
	return field


func _label(text_value: String, font_size: int, color: Color, use_heading: bool = false, centered: bool = false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font: Font = _body_font
	if use_heading:
		font = _title_font if font_size >= 28 else _heading_font
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _progress_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 8
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.14, 0.17, 0.13, 1)
	background.corner_radius_top_left = 5
	background.corner_radius_top_right = 5
	background.corner_radius_bottom_left = 5
	background.corner_radius_bottom_right = 5
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill
	foreground.corner_radius_top_left = 5
	foreground.corner_radius_top_right = 5
	foreground.corner_radius_bottom_left = 5
	foreground.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)
	return bar


func _hairline() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.72, 0.59, 0.36, 0.38)
	line.custom_minimum_size.y = 1
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return line


func _clear_content() -> void:
	for child: Node in _content.get_children():
		child.queue_free()


func _t(key: String, replacements: Dictionary = {}) -> String:
	return I18n.t(key, replacements)
