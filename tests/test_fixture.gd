extends Node

var game: Node3D
var assertions := 0
var failures := 0
var suite_name := "DEMO 2.5D"
var auto_quit := true

func _ready() -> void:
	call_deferred("run")

func verify(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for frame_index in range(count):
		await get_tree().physics_frame

func open_demo() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await get_tree().process_frame
	StationJourney.persistence_enabled = false
	StationJourney.reset()
	game = load("res://scenes/regions/recife.tscn").instantiate()
	add_child(game)
	await frames(14)
	game.hud.touch.persistence_enabled = false

func move_to(position_x: float) -> void:
	var ticks := 0
	while absf(game.player.position.x-position_x)>0.16 and ticks < 900:
		Input.action_press("move_right" if game.player.position.x < position_x else "move_left")
		await frames(1)
		Input.action_release("move_left")
		Input.action_release("move_right")
		ticks += 1
	await frames(8)
	verify(absf(game.player.position.x-position_x)<0.5,"Rota física até x=%.1f (atual %.2f, y %.2f)"%[position_x,game.player.position.x,game.player.position.y])

func climb_to(height: float) -> void:
	var action := "climb_up" if game.player.position.y < height else "climb_down"
	Input.action_press(action)
	await frames(85)
	Input.action_release(action)
	await frames(12)
	verify(absf(game.player.position.y-height)<0.2,"Escada física até y=%.1f (atual %.2f)"%[height,game.player.position.y])

func use_near(object_id: String) -> void:
	await get_tree().process_frame
	verify(game.nearest == object_id,"Proximidade real seleciona "+object_id+"; atual "+game.nearest)
	game.try_interact()
	await frames(1)
	if game.hud.modal_open:
		game.hud.close_modal()
func run() -> void:
	pass
