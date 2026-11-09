extends "res://tests/test_fixture.gd"

func open_station(region: String) -> void:
	if is_instance_valid(game):
		game.queue_free()
		await get_tree().process_frame
	StationJourney.station = region
	StationJourney.stage = "stations"
	game = load("res://scenes/regions/%s.tscn"%region).instantiate()
	add_child(game)
	await frames(16)
	game.hud.touch.persistence_enabled = false
	if game.hud.modal_open:game.hud.close_modal()
	await frames(12)

func climb_to(height: float) -> void:
	var action := "climb_up" if game.player.position.y<height else "climb_down"
	var direction := 1 if action=="climb_up" else -1
	Input.action_press(action)
	var ticks := 0
	while (height-game.player.position.y)*direction>0.02 and ticks<220:
		await frames(1)
		ticks += 1
	Input.action_release(action)
	Input.action_press("move_left")
	await frames(3)
	Input.action_release("move_left")
	await frames(10)
	verify(absf(game.player.position.y-height)<0.2,"Desembarque da escada no andar %.1f, atual %.2f"%[height,game.player.position.y])

func operate(object_id: String, expected := true) -> void:
	await frames(2)
	verify(game.nearest==object_id,"Proximidade real: "+object_id+" (atual "+game.nearest+")")
	verify(game.interact_object(object_id)==expected,"Ação "+object_id)
	if game.hud.modal_open and game.modal_is_dialogue():game.hud.close_modal()

func mode(gaia: bool) -> void:
	if game.perspectives.active!=gaia:game.toggle_gaia()
	await frames(2)

func water_route(choice := "RESTORE") -> void:
	await open_station("water")
	verify(game.player.is_on_floor(),"Piso 3D da estação")
	verify(not game.interact_object("route"),"Roteador digital bloqueado no físico")
	verify(not game.interact_object("door"),"Comporta não abre antes da cooperação")
	await mode(true)
	verify(not game.interact_object("module"),"GAIA não transporta módulo físico")
	await move_to(5)
	await operate("route")
	game.configure_system("water_route",0)
	game.hud.close_modal()
	verify(not game.interact_object("drain"),"Rota contaminada não autoriza drenagem")
	game.configure_system("water_route",1)
	await move_to(9)
	await operate("drain")
	await frames(90)
	verify(StationJourney.value("water_drained")==1 and game.environment.flood.position.y< -3,"Drenagem remota altera nível físico da água")
	await move_to(6)
	await climb_to(2.6)
	await move_to(8)
	await operate("memory")
	verify(game.perspectives.memory.visible and StationJourney.value("water_memory")==1,"Memória apresentada como projeção histórica")
	await move_to(6)
	await climb_to(0)
	await mode(false)
	await move_to(11)
	await climb_to(-2.7)
	await move_to(15)
	await operate("module")
	verify(StationJourney.value("water_module")==1,"Transporte físico real do módulo")
	await move_to(11)
	await climb_to(0)
	await move_to(18)
	await operate("install")
	await move_to(12)
	await operate("valve_a")
	await operate("valve_a")
	await move_to(23)
	await climb_to(2.6)
	await move_to(22)
	await operate("valve_b")
	await operate("valve_b")
	verify(game.system.pressure()==60,"Duas válvulas compõem pressão hidráulica")
	await mode(true)
	await move_to(25)
	await operate("authorize")
	verify(StationJourney.value("water_authorized")==1,"GAIA valida pressão, módulo e rota")
	await mode(false)
	await move_to(23)
	await climb_to(0)
	await move_to(20)
	await operate("pump")
	await frames(90)
	verify(game.environment.reservoir.scale.y>3,"Bomba preenche o reservatório")
	await move_to(27)
	await operate("door")
	await frames(75)
	verify(game.environment.gate.collision_layer==0,"Comporta perde bloqueio após puzzle")
	await move_to(31)
	await operate("decision")
	game.hud.close_modal()
	game.finish(choice)
	game.hud.close_modal()
	verify(StationJourney.choices.water==choice,"Escolha ambiental persistente")
	verify(game.environment.reservoir_paint.albedo_color==(Color("3e9eac") if choice=="RESTORE" else Color("586b57")),"A água reflete o destino escolhido")

	await move_to(33)
	await operate("exit")
	verify(game.hud.modal_open,"Transmissor abre a confirmação final")
	game.hud.modal_box.get_child(2).pressed.emit()
	await frames(3)
	verify(StationJourney.stage=="ending" and SceneRouter.last_requested=="ending","Percurso físico chega ao final")
	verify(StationJourney.ending()==("ending_a" if choice=="RESTORE" else "ending_b"),"Desfecho corresponde à escolha")

func run() -> void:
	StationJourney.persistence_enabled = false
	SceneRouter.test_mode = true
	for choice in ["RESTORE","EXODUS"]:
		StationJourney.reset()
		await water_route(choice)
	game.queue_free()
	await frames(6)
	print("CAPIBARIBE / DOIS FINAIS: %d verificações, %d falhas"%[assertions,failures])
	get_tree().quit(0 if failures==0 else 1)
