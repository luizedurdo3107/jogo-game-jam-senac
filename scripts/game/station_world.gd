extends Node3D

var station_id := "water"
var journey: Node
var system: RefCounted
var environment: Node3D
var perspectives: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var audio: AudioStreamPlayer
var soundscape: Node
var data: Dictionary
var objects: Dictionary = {}
var markers: Dictionary = {}
var nearest := ""
var finished := false
var metrics: Dictionary = {}
var carried_module: MeshInstance3D
var route_paths: Array[int] = []

func _ready() -> void:
	if not journey:
		journey = StationJourney
	journey.station = station_id
	journey.stage = "stations"
	journey.active = true
	GameState.persistence_enabled = false
	GameState.gaia_unlocked = true
	GameState.gaia_active = false
	GameState.input_locked = false
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/%s.json"%station_id))
	system = preload("res://scripts/puzzles/water_system.gd").new()
	system.journey = journey
	environment = Node3D.new()
	environment.set_script(preload("res://scripts/environments/station_environment.gd"))
	environment.station_id = station_id
	add_child(environment)
	player = CharacterBody3D.new()
	player.set_script(preload("res://scripts/game/player_controller.gd"))
	player.world = environment
	player.position = journey.checkpoint()
	add_child(player)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.8
	camera.position = Vector3(player.position.x+3.1,player.position.y+7.7,22)
	add_child(camera)
	camera.look_at(Vector3(player.position.x+1.1,player.position.y+2.5,-1))
	for item in data.objects:
		objects[item.id] = item
		_spawn_object(item)
	perspectives = Node3D.new()
	perspectives.set_script(preload("res://scripts/game/perspective_controller.gd"))
	perspectives.extent = Vector2(data.width,data.height)
	add_child(perspectives)
	perspectives.register_physical(environment)
	perspectives.register_mode(environment.fog_root,"physical")
	for object_id in markers:
		perspectives.register_physical(markers[object_id])
		var item: Dictionary = objects[object_id]
		if item.get("mode","")=="gaia" or item.get("kind","")=="npc":
			perspectives.register_mode(markers[object_id],item.mode)
		perspectives.add_outline(Vector3(item.at[0],item.at[1],-0.4),Vector3(0.8,1.3,0.75),item.get("mode","")=="physical")
	_build_digital_network()
	var module_shape := BoxMesh.new()
	module_shape.size = Vector3(0.3,0.4,0.25)
	carried_module = environment.mesh(player,module_shape,Vector3(-0.25,0.9,-0.12),Color("bd985b"))
	audio = AudioStreamPlayer.new()
	audio.volume_db = -9
	add_child(audio)
	hud = CanvasLayer.new()
	hud.set_script(preload("res://scripts/ui/station_hud.gd"))
	hud.world = self
	add_child(hud)
	soundscape = AudioDirector.attach_world(self,station_id,player)
	perspectives.changed.connect(func(_active): _refresh())
	_refresh(true)
	if not journey.checkpoints.has(station_id):
		hud.show_dialogue(str(data.title),str(data.intro))

func _spawn_object(item: Dictionary) -> void:
	var root := Node3D.new()
	root.name = item.id
	root.position = Vector3(item.at[0],item.at[1],-0.4)
	add_child(root)
	markers[item.id] = root
	var kind := str(item.get("kind","terminal"))
	var shape := BoxMesh.new()
	shape.size = Vector3(0.55,0.85,0.4)
	if kind=="npc":
		shape.size = Vector3(0.42,1.25,0.4)
		environment.mesh(root,shape,Vector3(0,0.62,0),Color("bb916d"))
		var head := SphereMesh.new()
		head.radius = 0.2
		head.height = 0.4
		head.radial_segments = 12
		head.rings = 6
		environment.mesh(root,head,Vector3(0,1.45,0),Color("d3a57c"))
	elif kind=="valve":
		var pivot := Node3D.new()
		pivot.position.y = 0.8
		root.add_child(pivot)
		var rim := TorusMesh.new()
		rim.inner_radius = 0.28
		rim.outer_radius = 0.38
		rim.rings = 16
		rim.ring_segments = 6
		var wheel: MeshInstance3D = environment.mesh(pivot,rim,Vector3.ZERO,Color("bf734a"))
		wheel.rotation.x = PI*0.5
		var spoke := BoxMesh.new()
		spoke.size = Vector3(0.65,0.055,0.06)
		environment.mesh(pivot,spoke,Vector3(0,0,0.05),Color("d5a65c"))
		if station_id=="water":
			environment.valve_visuals["water_a" if item.id=="valve_a" else "water_b"] = pivot
	else:
		environment.mesh(root,shape,Vector3(0,0.43,0),Color("30495a") if item.mode=="physical" else Color("28637a"))
		var screen := BoxMesh.new()
		screen.size = Vector3(0.38,0.32,0.04)
		environment.mesh(root,screen,Vector3(0,0.63,0.23),Color("9bd7bd"),true)
	var sign := Label3D.new()
	sign.text = "G" if item.mode=="gaia" else ("SAÍDA" if kind=="exit" else "E")
	sign.position.y = 1.55
	sign.font_size = 34
	sign.pixel_size = 0.008
	sign.modulate = SignalTheme.TEAL if item.mode=="gaia" else SignalTheme.GOLD
	root.add_child(sign)

func _build_digital_network() -> void:
	for item in data.objects:
		if item.mode=="gaia":
			var at := Vector3(item.at[0],item.at[1]+0.9,0.3)
			perspectives.add_data(str(item.label),at+Vector3(0,1.1,-0.1))
	metrics.pressure = perspectives.add_data("",Vector3(22,4.5,0.4))
	metrics.flow = perspectives.add_data("",Vector3(15,-0.7,0.5))
	for index in range(3):
		route_paths.append(perspectives.add_path([Vector3(5,1.1,0.4),Vector3(5,4.9+index*0.35,0.4),Vector3(14+index*2,4.9+index*0.35,0.4),Vector3(14+index*2,0.8,0.4)],Color("c8a86d") if index!=1 else Color("68cdbb")))

func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if event.is_action_pressed("pause_game"):
		if hud.modal_open: hud.close_modal()
		else: hud.show_pause()
	elif event.is_action_pressed("perspective"):
		toggle_gaia()
	elif event.is_action_pressed("interact"):
		if hud.modal_open and modal_is_dialogue():hud.close_modal()
		elif not hud.modal_open:try_interact()
	elif event.is_action_pressed("objective") or event.is_action_pressed("journal") or event.is_action_pressed("map_region"):
		if not hud.modal_open:hud.show_help()
	else:
		return
	viewport.set_input_as_handled()

func modal_is_dialogue() -> bool:
	return hud.modal_box.get_child_count()==3

func _process(delta: float) -> void:
	if not hud:return
	camera.position.x = lerpf(camera.position.x,clampf(player.position.x+3.1,7,31),1-exp(-delta*5))
	camera.position.y = lerpf(camera.position.y,player.position.y+7.7,1-exp(-delta*3))
	_update_interactions()

func _physics_process(_delta: float) -> void:
	if not hud or hud.modal_open or hud.portrait.visible:return
	if journey.value("water_drained")==0 and player.position.x>10 and player.position.x<19 and player.position.y< -0.85:
		player._end_climb()
		player.position = Vector3(9,0.1,0)
		player.velocity = Vector3.ZERO
		hud.notify("Câmara alagada. GAIA pode drenar o setor remotamente. Nenhum item foi perdido.")
func _update_interactions() -> void:
	nearest = ""
	var distance := 1.25
	for object_id in objects:
		var item: Dictionary = objects[object_id]
		if item.mode=="gaia" and not perspectives.active:continue
		var separation := Vector2(player.position.x-float(item.at[0]),player.position.y-float(item.at[1])).length()
		if separation<distance:
			distance = separation
			nearest = object_id
	hud.context.text = "E / "+str(objects[nearest].label) if not nearest.is_empty() else ("CAMADA DIGITAL / siga os circuitos e as falhas" if perspectives.active else "MUNDO FÍSICO / escadas amarelas e mecanismos")

func try_interact() -> void:
	_update_interactions()
	if nearest.is_empty():
		hud.notify("Aproxime-se de um equipamento do andar atual.")
		return
	interact_object(nearest)

func interact_object(object_id: String) -> bool:
	if hud.modal_open or hud.portrait.visible or not objects.has(object_id):return false
	var item: Dictionary = objects[object_id]
	if not perspectives.allows(item.mode):
		hud.notify(perspectives.blocked_feedback(item.mode))
		return false
	var kind := str(item.get("kind",""))
	if kind=="decision":
		if journey.value(station_id+"_open")!=1:
			hud.notify("O núcleo só pode ser distribuído depois de restaurar o acesso seguro.")
			return false
		if journey.choices[station_id]!="PENDING":
			hud.notify("Destino já registrado: "+journey.choices[station_id])
			return false
		hud.show_decision()
		return true
	if kind=="exit":
		if journey.choices[station_id]=="PENDING":
			hud.notify("Registre o destino do núcleo antes de transmitir o último sinal.")
			return false
		hud.show_signal_summary()
		return true
	var previous_values: Dictionary = journey.values.duplicate()
	var result: Dictionary = system.interact(str(item.get("command","")))
	if previous_values!=journey.values:
		_save_checkpoint()
		_refresh()
	if result.get("ok",false):
		_save_checkpoint()
		_refresh()
		soundscape.interaction(object_id,kind,perspectives.active,markers[object_id].global_position)
		if result.has("panel"):hud.show_system_panel(result.panel)
		elif result.has("memory"):
			perspectives.show_memory(station_id,Vector3(item.at[0],item.at[1],0))
			hud.show_dialogue(result.memory,result.message)
		else:hud.notify(result.get("message","Conexão atualizada."))
	else:hud.notify(result.message)
	return bool(result.get("ok",false))

func configure_system(panel: String, argument: int) -> Dictionary:
	var mode := "gaia"
	if not perspectives.allows(mode):return {"ok":false,"message":perspectives.blocked_feedback(mode)}
	var result: Dictionary = system.configure(panel,argument)
	if result.get("ok",false):
		_save_checkpoint()
		_refresh()
		soundscape.emit("circuit" if mode=="gaia" else "ui_confirm",player.global_position)
	return result

func toggle_gaia() -> bool:
	if hud.modal_open or hud.portrait.visible:return false
	perspectives.set_active(not perspectives.active)
	hud.notify("[GAIA] Circuitos, dados e controles remotos disponíveis." if perspectives.active else "[CORPO] Transporte, diálogo e mecanismos físicos disponíveis.")
	return true

func _save_checkpoint() -> void:
	if player.is_on_floor() and not player.climbing:
		var point := player.position
		journey.store_checkpoint(point)
	if not journey.save_game():hud.notify("Não foi possível gravar o checkpoint. Verifique o armazenamento.")

func _refresh(instant := false) -> void:
	environment.update_state(journey,instant)
	if carried_module:carried_module.visible = journey.value("water_module")==1
	if not metrics.is_empty():
		metrics.pressure.text = "PRESSÃO %d / 60 kPa\nVÁLVULAS A%d + B%d"%[system.pressure(),journey.value("water_a"),journey.value("water_b")]
		metrics.flow.text = "CÂMARA DRENADA" if journey.value("water_drained")==1 else "ALAGAMENTO / DRENAGEM REMOTA"
		for index in range(route_paths.size()):perspectives.set_path_enabled(route_paths[index],journey.value("water_route")==index)
	if hud:
		hud.refresh()
		_update_interactions()

func current_objective() -> String:
	return system.objective()

func finish(choice: String) -> void:
	if journey.decide(choice):
		_refresh()
		play_sound("restore" if choice=="RESTORE" else "exodus")
		hud.show_dialogue("DESTINO REGISTRADO",("Recuperação localizada iniciada. O resto do Recife ainda exige cuidado." if choice=="RESTORE" else "Núcleo reservado para a ARCA-01. A infraestrutura local permanece em modo mínimo.")+"\n\nSiga ao transmissor à direita para confirmar o último sinal e assistir ao final.")
	else:
		hud.notify("Destino não registrado. Confira o puzzle e o armazenamento antes de tentar novamente.")

func play_sound(sound_id: String) -> void:
	var resolved := str(AudioDirector.ALIASES.get(sound_id,sound_id))
	audio.stream = AudioDirector.stream_for(resolved)
	if soundscape:soundscape.emit(resolved,player.global_position)

func set_muted(muted: bool) -> void:
	audio.volume_db = -80 if muted else -9
	perspectives.set_muted(muted)

func restart() -> void:
	hud.touch.release_all()
	get_tree().reload_current_scene()

func menu() -> void:
	hud.touch.release_all()
	journey.leave()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _exit_tree() -> void:
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null
