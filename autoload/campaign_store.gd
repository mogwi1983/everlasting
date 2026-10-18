extends Node

signal campaign_changed(campaign: Dictionary)

const SAVE_PATH := "user://everlasting_delve_campaign.json"
const TEMP_PATH := "user://everlasting_delve_campaign.tmp"
const SAVE_SCHEMA := 1

var _campaign: Dictionary = {}


func _ready() -> void:
	_load_saved_campaign()


func has_campaign() -> bool:
	return not _campaign.is_empty() and _campaign.has("hero")


func get_campaign() -> Dictionary:
	return _campaign.duplicate(true)


func save_campaign(campaign: Dictionary) -> bool:
	if not campaign.has("hero") or not campaign.has("inventory"):
		push_error("CampaignStore rejected an incomplete campaign.")
		return false
	var payload := campaign.duplicate(true)
	payload["schema_version"] = SAVE_SCHEMA
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("CampaignStore could not open its temporary save file.")
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var absolute_temp := ProjectSettings.globalize_path(TEMP_PATH)
	var absolute_save := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(absolute_save)
		if remove_error != OK:
			push_error("CampaignStore could not replace the previous campaign save.")
			return false
	var rename_error := DirAccess.rename_absolute(absolute_temp, absolute_save)
	if rename_error != OK:
		push_error("CampaignStore could not finalize the campaign save.")
		return false
	_campaign = payload
	campaign_changed.emit(_campaign.duplicate(true))
	return true


func reload_campaign() -> Dictionary:
	_load_saved_campaign()
	return get_campaign()


func _load_saved_campaign() -> void:
	_campaign = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SAVE_SCHEMA and parsed.has("hero") and parsed.has("inventory"):
		_campaign = (parsed as Dictionary).duplicate(true)
	else:
		push_warning("The local campaign save could not be read; a new story can be started without changing it.")
