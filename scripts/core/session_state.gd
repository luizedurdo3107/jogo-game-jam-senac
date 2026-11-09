extends Node

signal changed

const SETTINGS_PATH := "user://settings.cfg"

var player_name := ""
var default_player_name := ""
var gaia_unlocked := false
var gaia_active := false
var flags: Dictionary = {}
var values: Dictionary = {}
var station_choices: Dictionary = {"water": "PENDING", "soil": "PENDING", "air": "PENDING"}
var inventory: Array = []
var input_locked := false
var volume := 0.45
var persistence_enabled := true

func _ready() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_config.json"))
	default_player_name = str(config.get("player_name", "Protagonista"))
	player_name = default_player_name
	var bindings: Dictionary = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "climb_up": [KEY_W, KEY_UP], "climb_down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE], "journal": [KEY_J], "map_region": [KEY_M], "interact": [KEY_E], "perspective": [KEY_Q], "objective": [KEY_TAB], "pause_game": [KEY_ESCAPE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		set_volume(float(settings.get_value("audio", "volume", 0.45)), false)
	else:
		set_volume(volume, false)

func reset() -> void:
	player_name = default_player_name
	gaia_unlocked = false
	gaia_active = false
	flags.clear()
	values.clear()
	inventory.clear()
	station_choices = {"water":"PENDING","soil":"PENDING","air":"PENDING"}
	input_locked = false
	changed.emit()

func has_flag(flag: String) -> bool:
	return bool(flags.get(flag,false))

func matches(requirements: Dictionary) -> bool:
	for key in requirements:
		if has_flag(key)!=bool(requirements[key]):
			return false
	return true

func apply_effect(effect: Dictionary) -> void:
	if effect.has("give_item") and not inventory.has(effect.give_item):
		inventory.append(str(effect.give_item))
	if effect.has("take_item"):
		inventory.erase(str(effect.take_item))
	for flag in effect.get("flags",[]):
		flags[flag] = true
	if effect.get("unlock_gaia",false):
		gaia_unlocked = true
	changed.emit()

func set_volume(value: float, persist := true) -> void:
	volume = clampf(value,0,1)
	if is_instance_valid(get_node_or_null("/root/AudioDirector")) and not AudioDirector.catalog.is_empty():
		AudioDirector.set_volume("Master",volume,persist)
