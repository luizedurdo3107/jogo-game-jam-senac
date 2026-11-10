extends Node

var test_mode := false
var last_requested := ""
var queued_path := ""

func change_scene(path: String) -> void:
	if test_mode or not queued_path.is_empty():return
	queued_path = path
	call_deferred("_change_scene")

func prepare_scene(scene: Node) -> void:
	if not is_instance_valid(scene):return
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	for animation in scene.find_children("*","AnimationPlayer",true,false):animation.stop()

func _change_scene() -> void:
	var path := queued_path
	queued_path = ""
	var previous := get_tree().current_scene
	var previous_mode := previous.process_mode if is_instance_valid(previous) else Node.PROCESS_MODE_INHERIT
	prepare_scene(previous)
	var error := get_tree().change_scene_to_file(path)
	if error!=OK:
		if is_instance_valid(previous):previous.process_mode = previous_mode
		push_error("Não foi possível abrir a cena: "+path)

func menu() -> void:
	get_tree().paused = false
	GameState.input_locked = false
	last_requested = "menu"
	StationJourney.leave()
	change_scene("res://scenes/ui/main_menu.tscn")
