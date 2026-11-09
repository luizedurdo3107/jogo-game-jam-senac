extends Node

var test_mode := false
var last_requested := ""

func menu() -> void:
	get_tree().paused = false
	GameState.input_locked = false
	last_requested = "menu"
	StationJourney.leave()
	if not test_mode:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
