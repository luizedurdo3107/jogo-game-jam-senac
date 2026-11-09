extends Node3D

@export var station_id := "water"
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
var lift: AnimatableBody3D
var lift_target := 0.0
var lift_moving := false
var lift_bridges: Array[Dictionary] = []
var drone: Node3D
var elapsed := 0.0
var suspicion := 0.0
var metrics: Dictionary = {}
var carried_module: MeshInstance3D
var route_paths: Array[int] = []

func _ready() -> void:
	if not journey:
		journey = StationJourney
	if station_id!="nexus":journey.station = station_id
	journey.active = true
	GameState.persistence_enabled = false
	GameState.gaia_unlocked = true
	GameState.gaia_active = false
	GameState.input_locked = false
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/%s.json"%station_id))
	system = load("res://scripts/puzzles/%s_system.gd"%station_id).new()
	system.journey = journey
	environment = Node3D.new()
	environment.set_script(load("res://scripts/environments/nexus_environment.gd") if station_id=="nexus" else preload("res://scripts/environments/station_environment.gd"))
	environment.station_id = station_id
	add_child(environment)
	player = CharacterBody3D.new()
	player.set_script(preload("res://scripts/game/player_controller.gd"))
	player.world = environment
	player.position = journey.checkpoint()
	add_child(player)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0 if station_id=="soil" else 11.8
	camera.position = Vector3(player.position.x+3.1,player.position.y+7.7,22)
	add_child(camera)
	camera.look_at(Vector3(player.position.x+1.1,player.position.y+2.5,-1))
	for item in data.objects:
		objects[item.id] = item
		_spawn_object(item)
	if station_id=="air":
		_create_lift()
		_create_drone()
	perspectives = Node3D.new()
	perspectives.set_script(preload("res://scripts/game/perspective_controller.gd"))
	perspectives.extent = Vector2(data.width,data.height)
	add_child(perspectives)
	perspectives.register_physical(environment)
	perspectives.register_mode(environment.fog_root,"physical")
	if drone:perspectives.register_physical(drone)
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
	hud.set_script(load("res://scripts/ui/nexus_hud.gd") if station_id=="nexus" else preload("res://scripts/ui/station_hud.gd"))
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
	var path: Array = []
	for item in data.objects:
		if item.mode=="gaia":
			var at := Vector3(item.at[0],item.at[1]+0.9,0.3)
			path.append(at)
			perspectives.add_data(str(item.label),at+Vector3(0,1.1,-0.1))
	if station_id=="nexus":perspectives.add_path(path)
	if station_id=="soil":
		perspectives.add_path([Vector3(17,1,0.4),Vector3(23,1,0.4),Vector3(23,3.5,0.4),Vector3(11,3.5,0.4)])
	if station_id=="water":
		metrics.pressure = perspectives.add_data("",Vector3(22,4.5,0.4))
		metrics.flow = perspectives.add_data("",Vector3(15,-0.7,0.5))
		for index in range(3):
			route_paths.append(perspectives.add_path([Vector3(5,1.1,0.4),Vector3(5,4.9+index*0.35,0.4),Vector3(14+index*2,4.9+index*0.35,0.4),Vector3(14+index*2,0.8,0.4)],Color("c8a86d") if index!=1 else Color("68cdbb")))
	elif station_id=="soil":
		for index in range(4):
			metrics[str(index)] = perspectives.add_data("",Vector3(10+index*3.4,4.2,-1.7))
		metrics.climate = perspectives.add_data("",Vector3(17,1.8,0.5))
	elif station_id=="air":
		metrics.air = perspectives.add_data("",Vector3(12,6.7,0.5))
		perspectives.add_path([Vector3(15,6.1,0.4),Vector3(17,3.5,0.4),Vector3(15,8.7,0.4)],Color("c4d4a2"))

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

func _physics_process(delta: float) -> void:
	if not hud or hud.modal_open or hud.portrait.visible:return
	elapsed += delta
	if station_id=="water" and journey.value("water_drained")==0 and player.position.x>10 and player.position.x<19 and player.position.y< -0.85:
		player._end_climb()
		player.position = Vector3(9,0.1,0)
		player.velocity = Vector3.ZERO
		hud.notify("Câmara alagada. GAIA pode drenar o setor remotamente. Nenhum item foi perdido.")
	if lift_moving:
		lift.position.y = move_toward(lift.position.y,lift_target-0.12,delta*1.8)
		if absf(lift.position.y-(lift_target-0.12))<0.005:lift_moving = false
	for bridge in lift_bridges:
		var open: bool = absf(lift.position.y+0.12-float(bridge.height))<2.15
		bridge.body.collision_layer = 0 if open else 1
		bridge.visual.visible = not open
	if drone:
		var destination := Vector3(2,9.7,-0.1) if journey.value("air_drone")==1 else Vector3(15+sin(elapsed*0.5)*3,7.8,-0.1)
		drone.position = drone.position.lerp(destination,1-exp(-delta*2))
		var detected: bool = journey.value("air_drone")==0 and absf(player.position.x-drone.position.x)<0.9 and absf(player.position.y-5.2)<0.4
		suspicion = suspicion+delta if detected else maxf(0,suspicion-delta*2)
		if suspicion>0.5:hud.notify("DRONE / Inspeção. Use a manutenção digital ou a escada lateral. Sem combate.")
		if suspicion>2.5:
			player._end_climb()
			player.position = journey.checkpoint()
			player.velocity = Vector3.ZERO
			suspicion = 0

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
	if kind=="final":
		if journey.value("nexus_open")!=1:
			hud.notify("Abra o painel protegido com o corpo após a validação de GAIA.")
			return false
		hud.show_final()
		return true
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
			hud.notify("Registre o destino do núcleo antes de seguir.")
			return false
		journey.advance()
		return true
	if kind=="lift":return operate_lift()
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
		elif result.has("technician"):hud.show_technician()
		else:hud.notify(result.get("message","Conexão atualizada."))
	else:hud.notify(result.message)
	return bool(result.get("ok",false))

func configure_system(panel: String, argument: int) -> Dictionary:
	var mode := "physical" if panel=="air_team" else "gaia"
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
		if station_id=="air" and absf(point.x-8)<0.8:point.x = 9.2
		journey.store_checkpoint(point)
	if not journey.save_game():hud.notify("Não foi possível gravar o checkpoint. Verifique o armazenamento.")

func _refresh(instant := false) -> void:
	environment.update_state(journey,instant)
	if carried_module:
		carried_module.visible = journey.value({"water":"water_module","soil":"soil_filter","air":"air_module"}.get(station_id,""))==1
	if not metrics.is_empty():
		match station_id:
			"water":
				metrics.pressure.text = "PRESSÃO %d / 60 kPa\nVÁLVULAS A%d + B%d"%[system.pressure(),journey.value("water_a"),journey.value("water_b")]
				metrics.flow.text = "CÂMARA DRENADA" if journey.value("water_drained")==1 else "ALAGAMENTO / DRENAGEM REMOTA"
				for index in range(route_paths.size()):perspectives.set_path_enabled(route_paths[index],journey.value("water_route")==index)
			"soil":
				for index in range(4):
					metrics[str(index)].text = ["A / CONTAMINADA 85%","B / VIÁVEL 92%","C / MEMBRANA ROMPIDA","D / VIÁVEL 88%"][index]+("\nCONECTADA" if journey.value("soil_mask")&(1<<index) else "\nDESCONECTADA")
				metrics.climate.text = "UMIDADE %d%% / TÉRMICO %d°C"%[system.HUMIDITY[journey.value("soil_humidity")],system.TEMPERATURE[journey.value("soil_temperature")]]
			"air":metrics.air.text = "PARTÍCULAS %d µg/m³\nDUTOS %d / 3"%[38 if journey.choices.air=="RESTORE" else 168,journey.value("air_sequence")]
	if hud:
		hud.refresh()
		_update_interactions()

func current_objective() -> String:
	return system.objective()

func finish(choice: String) -> void:
	if journey.decide(choice):
		_refresh()
		play_sound("restore" if choice=="RESTORE" else "exodus")
		hud.show_dialogue("DESTINO REGISTRADO",("Recuperação localizada iniciada. O resto do Recife ainda exige cuidado." if choice=="RESTORE" else "Núcleo reservado para a ARCA-01. A infraestrutura local permanece em modo mínimo.")+"\n\nSiga ao acesso da próxima região. A maioria dos três destinos determina o final.")

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

func _create_lift() -> void:
	lift = AnimatableBody3D.new()
	lift.set_meta("audio_surface","metal")
	lift.position = Vector3(8,-0.12,0)
	lift.collision_layer = 1
	lift.collision_mask = 2
	add_child(lift)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1,0.24,2.2)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	lift.add_child(collider)
	environment.platforms.append(lift)
	var platform := BoxMesh.new()
	platform.size = shape.size
	environment.mesh(lift,platform,Vector3.ZERO,SignalTheme.GOLD)
	for height in environment.lift_stops:
		if height==0:continue
		var bridge: StaticBody3D = environment.solid(Vector3(8,height-0.1,0),Vector3(1.2,0.2,2.2))
		var grating := BoxMesh.new()
		grating.size = Vector3(1.2,0.2,2.2)
		var visual: MeshInstance3D = environment.mesh(environment,grating,Vector3(8,height-0.1,0),Color("a28c58"))
		lift_bridges.append({"body":bridge,"visual":visual,"height":height})

func operate_lift() -> bool:
	if journey.value("air_module")!=2 or lift_moving:
		hud.notify("Elevador indisponível: instale o módulo no arranque; aguarde a cabine parar. As escadas continuam acessíveis.")
		return false
	var index := 0
	for candidate in range(environment.lift_stops.size()):
		if absf(environment.lift_stops[candidate]-player.position.y)<absf(environment.lift_stops[index]-player.position.y):index = candidate
	var stop_y: float = environment.lift_stops[index]
	lift_target = stop_y if absf(lift.position.y+0.12-stop_y)>0.25 else environment.lift_stops[(index+1)%environment.lift_stops.size()]
	lift_moving = true
	hud.notify("Elevador chamado. Entre no centro e aguarde a viagem.")
	return true

func _create_drone() -> void:
	drone = Node3D.new()
	add_child(drone)
	var body := BoxMesh.new()
	body.size = Vector3(0.7,0.22,0.4)
	environment.mesh(drone,body,Vector3.ZERO,Color("667b87"))
	var eye := SphereMesh.new()
	eye.radius = 0.07
	eye.height = 0.14
	eye.radial_segments = 8
	eye.rings = 4
	environment.mesh(drone,eye,Vector3(0,-0.05,0.25),SignalTheme.GOLD,true)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 1.1
	cone.height = 2.6
	cone.radial_segments = 12
	var beam: MeshInstance3D = environment.mesh(drone,cone,Vector3(0,-1.4,0),Color("c2c9a4"))
	var paint: StandardMaterial3D = beam.material_override.duplicate()
	paint.albedo_texture = null
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.albedo_color.a = 0.055
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = paint

func _exit_tree() -> void:
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null
