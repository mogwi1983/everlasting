extends Node

signal locale_changed(locale: String)

const LOCALE := "en"
const CATALOG_PATH := "res://localization/en.json"

var _catalog: Dictionary = {}


func _ready() -> void:
	_load_catalog()


func get_locale() -> String:
	return LOCALE


func detect_locale(_system_locale: String) -> String:
	return LOCALE


func resolve_locale(_saved_locale: String = "", _system_locale: String = "") -> String:
	return LOCALE


func set_locale(locale: String) -> void:
	if locale == LOCALE:
		locale_changed.emit(LOCALE)


func toggle_locale() -> void:
	# This game intentionally exposes one language only.
	return


func text(key: String, replacements: Dictionary = {}) -> String:
	var result := String(_catalog.get(key, key))
	for replacement_key: Variant in replacements.keys():
		result = result.replace("{" + String(replacement_key) + "}", str(replacements[replacement_key]))
	return result


func t(key: String, replacements: Dictionary = {}) -> String:
	return text(key, replacements)


func catalog_keys(locale: String = LOCALE) -> Array:
	if locale != LOCALE:
		return []
	return _catalog.keys()


func _load_catalog() -> void:
	_catalog = {}
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("The English game catalog is missing.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary:
		_catalog = parsed as Dictionary
	else:
		push_error("The English game catalog is not valid JSON.")
