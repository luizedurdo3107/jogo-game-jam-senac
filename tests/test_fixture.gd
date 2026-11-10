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

func defeat_nova(world: Node3D) -> void:
	await arm_nova(world)
	var attempts := 0
	while world.combat.mask!=7 and attempts<30 and not world.finished:
		var index: int = world.combat.current_enemy()
		if index<0:break
		var soldier: Dictionary = world.combat.soldiers[index]
		world.player.position = Vector3(6.5,0.05,0)
		world.combat.invulnerable = 100
		await frames(120)
		world.player.position = Vector3(soldier.body.position.x-1.0,0.05,0)
		world.player.sprite.flip_h = false
		soldier.clock = 1.3
		var before: int = soldier.life
		verify(world.attack(),"Golpe no combate de Nova Éden")
		verify(soldier.life<before,"Golpe causa dano no soldado")
		attempts += 1
		await frames(2)
	verify(world.combat.mask==7 and StationJourney.value("nova_open")==1,"Combate armado libera a saída da cidade")

func arm_nova(world: Node3D) -> void:
	if StationJourney.value("nova_weapon")==1:return
	world.player.position = Vector3(6.5,0.05,0)
	verify(world.interact_object("armory"),"Arsenal acessível")
	for relay in range(StationJourney.value("nova_armory"),3):verify(world.armory_relay(relay),"Relé do arsenal / "+str(relay))
	if world.hud.modal_open:world.hud.close_modal()
	verify(world.interact_object("armory") and world.combat.armed(),"Bastão coletado fisicamente após abrir o arsenal")

func defeat_departure(world: Node3D) -> void:
	if not world.combat.armed():verify(world.interact_object("equipment"),"Equipamento da doca fornece bastão sem novo puzzle")
	var attempts := 0
	while world.combat.mask!=7 and attempts<35 and not world.finished:
		var index: int = world.combat.current_enemy()
		if index<0:break
		var soldier: Dictionary = world.combat.soldiers[index]
		world.player.position = Vector3(6.5,0.05,0)
		world.combat.invulnerable = 100
		await frames(120)
		world.player.position = Vector3(soldier.body.position.x-1,0.05,0)
		world.player.sprite.flip_h = false
		soldier.clock = 1.3
		var before: int = soldier.life
		verify(world.attack(),"Bastão ataca a guarnição da doca")
		verify(soldier.life<before,"Soldado da doca sofre dano real")
		attempts += 1
		await frames(2)
	verify(world.combat.mask==7 and StationJourney.value("departure_security")==7,"Guarnição militar vencida antes do embarque")

func open_demo() -> void:
	if is_instance_valid(game):
		game.queue_free()
		await get_tree().process_frame
	StationJourney.persistence_enabled = false
	StationJourney.reset()
	StationJourney.stage = "intro"
	game = load("res://scenes/regions/laboratory.tscn").instantiate()
	add_child(game)
	await frames(14)
	game.hud.touch.persistence_enabled = false
	if game.hud.modal_open:game.hud.close_modal()

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
