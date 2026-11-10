extends Node3D

@export var region_id := "laboratory"

var environment: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var data: Dictionary
var objects: Dictionary = {}
var markers: Dictionary = {}
var nearest := ""
var finished := false
var elapsed := 0.0
var drone: Node3D
var suspicion := 0.0
var grace := 3.0
var lift: AnimatableBody3D
var lift_target := 0.0
var lift_stops := [-2.7,0.0,2.6]
var lift_moving := false
var audio: AudioStreamPlayer
var soundscape: Node
var checkpoint := Vector3(9,0.1,0)
var perspectives: Node3D
var carried_cell: MeshInstance3D

func _ready() -> void:
	GameState.persistence_enabled = false
	GameState.reset()
	StationJourney.active = true
	for flag in StationJourney.INTRO_FLAGS + StationJourney.STORY_FLAGS:
		if StationJourney.value(flag)==1:GameState.flags[flag] = true
	GameState.gaia_unlocked = GameState.has_flag("recife_awake")
	if GameState.has_flag("recife_cell") and not GameState.has_flag("recife_power"):GameState.inventory.append("recife_cell")
	GameState.input_locked = false
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions/%s.json"%region_id))
	environment = Node3D.new()
	if region_id=="boss":
		environment.set_script(preload("res://scripts/environments/departure_environment.gd"))
	elif region_id=="nova_eden":
		environment.set_script(preload("res://scripts/environments/nova_environment.gd"))
	else:
		environment.set_script(preload("res://scripts/environments/story_environment.gd"))
		environment.region_id = region_id
	environment.reduced = OS.has_feature("web") or DisplayServer.is_touchscreen_available()
	add_child(environment)
	get_viewport().scaling_3d_scale = 0.75 if environment.reduced else 1.0
	player = CharacterBody3D.new()
	player.set_script(preload("res://scripts/game/player_controller.gd"))
	player.world = environment
	player.position = StationJourney.checkpoint()
	add_child(player)
	var cell_shape := BoxMesh.new()
	cell_shape.size = Vector3(0.24,0.36,0.22)
	carried_cell = environment.mesh(player,cell_shape,Vector3(-0.3,0.95,-0.05),SignalTheme.TEAL,true)
	carried_cell.hide()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.4
	camera.position = Vector3(7,8,22)
	add_child(camera)
	camera.look_at(Vector3(5,2.8,-1))
	for item in data.objects:
		objects[item.id] = item
		_spawn_object(item)
	if region_id!="nova_eden":_create_lift()
	_create_drone()
	perspectives = Node3D.new()
	perspectives.set_script(preload("res://scripts/game/perspective_controller.gd"))
	add_child(perspectives)
	perspectives.register_physical(environment)
	var circuit_points: Array = []
	for item in data.objects:
		perspectives.register_physical(markers[item.id])
		perspectives.add_outline(Vector3(item.at[0],item.at[1],-0.4),Vector3(0.8,1.2,0.7),item.get("mode","physical")=="physical")
		if item.get("mode","")=="gaia":
			circuit_points.append(Vector3(item.at[0],item.at[1]+1,0.3))
			perspectives.add_data(str(item.label),Vector3(item.at[0],item.at[1]+2.1,0.2))
		elif item.get("kind","")=="npc":
			perspectives.register_mode(markers[item.id],"physical")
	perspectives.add_path(circuit_points)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -9
	add_child(audio)
	hud = CanvasLayer.new()
	hud.set_script(preload("res://scripts/ui/game_hud.gd"))
	hud.world = self
	add_child(hud)
	soundscape = AudioDirector.attach_world(self,region_id,player)
	GameState.changed.connect(_refresh)
	_refresh()
	hud.notify(str(data.tutorial))
	if not StationJourney.checkpoints.has(region_id):hud.show_dialogue(str(data.title),str(data.intro))

func _spawn_object(item: Dictionary) -> void:
	var root := Node3D.new()
	root.name = str(item.id)
	root.position = Vector3(item.at[0],item.at[1],-0.4)
	add_child(root)
	markers[item.id] = root
	var shape := BoxMesh.new()
	shape.size = Vector3(0.52,0.85,0.4)
	var kind := str(item.get("kind","terminal"))
	if kind == "npc":
		shape.size = Vector3(0.42,1.15,0.36)
		environment.mesh(root,shape,Vector3(0,0.6,0),Color("948071"))
		var head := SphereMesh.new()
		head.radius = 0.19
		head.height = 0.38
		head.radial_segments = 12
		head.rings = 6
		environment.mesh(root,head,Vector3(0,1.37,0),Color("ae8b6f"))
	else:
		environment.mesh(root,shape,Vector3(0,0.43,0),Color("303e50"))
		var screen := BoxMesh.new()
		screen.size = Vector3(0.38,0.35,0.025)
		environment.mesh(root,screen,Vector3(0,0.62,0.215),SignalTheme.TEAL,true)
		var label := Label3D.new()
		label.text = "G" if item.get("mode","") == "gaia" else ("+" if kind == "battery" else "E")
		label.position = Vector3(0,1.25,0)
		label.font_size = 40
		label.pixel_size = 0.007
		label.modulate = SignalTheme.TEAL if item.get("mode","") == "gaia" else SignalTheme.GOLD
		root.add_child(label)
		var detail := Node3D.new()
		detail.set_script(preload("res://scripts/game/device_detail.gd"))
		detail.environment = environment
		detail.item = item
		detail.world = self
		root.add_child(detail)

func _create_lift() -> void:
	lift = AnimatableBody3D.new()
	lift.set_meta("audio_surface","metal")
	lift.position = Vector3(23.2,-0.12,0)
	lift.collision_layer = 1
	lift.collision_mask = 2
	lift.sync_to_physics = true
	add_child(lift)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0,0.24,2.2)
	collider.shape = shape
	lift.add_child(collider)
	environment.platforms.append(lift)
	var platform := BoxMesh.new()
	platform.size = shape.size
	environment.mesh(lift,platform,Vector3.ZERO,SignalTheme.GOLD)

func _create_drone() -> void:
	drone = Node3D.new()
	add_child(drone)
	var body := BoxMesh.new()
	body.size = Vector3(0.7,0.22,0.45)
	environment.mesh(drone,body,Vector3.ZERO,Color("536d7f"))
	var eye := SphereMesh.new()
	eye.radius = 0.07
	eye.height = 0.14
	eye.radial_segments = 8
	eye.rings = 4
	environment.mesh(drone,eye,Vector3(0,-0.05,0.25),SignalTheme.GOLD,true)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 1.3
	cone.height = 3.1
	cone.radial_segments = 16
	var beam: MeshInstance3D = environment.mesh(drone,cone,Vector3(0,-1.65,0),Color("99c9d8"))
	var beam_material: StandardMaterial3D = beam.material_override.duplicate()
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.albedo_color.a = 0.055
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = beam_material

func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if event.is_action_pressed("pause_game"):
		if hud.modal_open and not finished:
			hud.close_modal()
		elif not finished:
			hud.show_pause()
		viewport.set_input_as_handled()
	elif event.is_action_pressed("objective") or event.is_action_pressed("journal") or event.is_action_pressed("map_region"):
		if not hud.modal_open:
			hud.show_help()
		viewport.set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if hud.modal_open and not finished:
			if modal_is_dialogue():
				hud.close_modal()
		else:
			try_interact()
		viewport.set_input_as_handled()
	elif event.is_action_pressed("perspective"):
		toggle_gaia()
		viewport.set_input_as_handled()

func modal_is_dialogue() -> bool:
	return hud.modal_box.get_child_count() == 3

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hud) or hud.modal_open or hud.portrait.visible or finished:
		return
	elapsed += delta
	grace = maxf(0,grace-delta)
	if lift_moving:
		lift.position.y = move_toward(lift.position.y,lift_target-0.12,delta*1.6)
		if absf(lift.position.y-(lift_target-0.12)) < 0.005:
			lift_moving = false
	if region_id=="nova_eden":
		_nova_security(delta)
		return
	drone.position = Vector3(20.7+sin(elapsed*0.35)*2.5,3.8,-0.15)
	if GameState.has_flag("recife_drone") or GameState.has_flag("ruins_drone"):
		drone.position.y = 6.0
		return
	var detected := absf(player.position.x-drone.position.x) < 1 and player.position.y > -0.4 and player.position.y < 1.0
	if detected and grace <= 0:
		suspicion += delta
		if suspicion > 0.6:
			hud.notify("DRONE / Inspeção. Evite pela passarela ou pelo túnel.")
		if suspicion > 2.3:
			player.position = checkpoint
			player.velocity = Vector3.ZERO
			player._end_climb()
			grace = 5
			suspicion = 0
			hud.notify("Drone solicitou retorno ao abrigo. Energia e progresso preservados.")
	else:
		suspicion = maxf(0,suspicion-delta*2)

func _process(delta: float) -> void:
	if not camera or not hud:
		return
	camera.position.x = lerpf(camera.position.x,clampf(player.position.x+3.1,7,35),1-exp(-delta*5))
	camera.position.y = lerpf(camera.position.y,player.position.y+8.0,1-exp(-delta*3))
	_update_interactions()

func _update_interactions() -> void:
	nearest = ""
	var distance := 1.35
	for object_id in objects:
		var item: Dictionary = objects[object_id]
		var marker: Node3D = markers[object_id]
		var gaia_only: bool = item.get("mode","") == "gaia"
		marker.visible = not gaia_only or GameState.gaia_active
		if item.get("kind","")=="battery" and GameState.has_flag(str(item.get("done",""))):marker.hide()
		if not marker.visible:
			continue
		if item.get("kind","") == "lift" and not GameState.has_flag("recife_power"):
			continue
		var separation := Vector2(player.position.x-float(item.at[0]),player.position.y-float(item.at[1])).length()
		if separation < distance:
			nearest = object_id
			distance = separation
	if not nearest.is_empty():
		hud.context.text = "E / AGIR · " + str(objects[nearest].label)
		if GameState.has_flag(str(objects[nearest].get("done",""))):
			hud.context.text = "[OK] Etapa concluída. Siga o objetivo."
	else:
		hud.context.text = "Célula transportada · procure o soquete." if GameState.inventory.has("recife_cell") else "Escadas amarelas conectam os três níveis."

func current_objective() -> String:
	for entry in data.objectives:
		if not GameState.has_flag(entry[0]):
			return entry[1]
	return "Siga para a próxima região."

func try_interact() -> void:
	if hud.modal_open or hud.portrait.visible or finished:
		return
	if nearest.is_empty():
		hud.notify("Aproxime-se de um terminal ou personagem para agir.")
		return
	interact_object(nearest)

func interact_object(object_id: String) -> bool:
	if hud.modal_open or finished or not objects.has(object_id):
		return false
	var item: Dictionary = objects[object_id]
	if item.get("mode","physical") == "gaia" and not GameState.gaia_active:
		hud.notify("[G] Só GAIA consegue ler este circuito. Alterne a perspectiva.")
		return false
	if item.get("mode","physical") == "physical" and GameState.gaia_active:
		hud.notify("[F] Volte ao corpo para manipular objetos físicos.")
		return false
	if GameState.has_flag(str(item.get("done",""))):
		hud.notify("[OK] Etapa já concluída. " + current_objective())
		return false
	if not GameState.matches(item.get("requires",{})) or item.has("requires_item") and not GameState.inventory.has(item.requires_item):
		hud.notify(item.get("blocked","Investigue os outros sistemas antes."))
		return false
	if item.get("kind","") == "lift":
		return operate_lift()
	if item.get("kind","") == "exit":
		hud.touch.release_all()
		if region_id=="nova_eden":
			StationJourney.put("nova_escaped",1)
		if StationJourney.advance_story():return true
		hud.notify("Não foi possível salvar a passagem. Tente novamente.")
		return false
	var effect: Dictionary = item.get("effect",{}).duplicate(true)
	if item.has("take_item"):
		effect.take_item = item.take_item
	GameState.apply_effect(effect)
	_save_progress()
	soundscape.interaction(object_id,str(item.get("kind","")),GameState.gaia_active,markers[object_id].global_position)
	if item.has("text"):
		if item.get("temporal","")=="past" or object_id=="archive":
			perspectives.show_memory("lab" if region_id=="laboratory" else "recife",Vector3(item.at[0],item.at[1],0))
			hud.show_memory(str(item.label),str(item.text))
		else:hud.show_dialogue(str(item.label),str(item.text))
	return true

func toggle_gaia() -> bool:
	if hud.modal_open or hud.portrait.visible or finished:
		return false
	if not GameState.gaia_unlocked:
		hud.notify("GAIA será encontrada no laboratório. Explore com o corpo por enquanto.")
		return false
	GameState.gaia_active = not GameState.gaia_active
	_refresh()
	hud.notify("[G] GAIA: circuitos e memórias revelados." if GameState.gaia_active else "[F] FÍSICO: módulos e mecanismos acessíveis.")
	return true

func _refresh() -> void:
	if not is_inside_tree():return
	if carried_cell:
		carried_cell.visible = region_id=="laboratory" and GameState.has_flag("recife_cell") and not GameState.has_flag("recife_power")
	if environment:
		environment.set_gaia(GameState.gaia_active)
		if GameState.has_flag(str(data.get("gate_flag",""))) and environment.gate.collision_layer!=0:environment.open_gate()
	if perspectives and perspectives.active!=GameState.gaia_active:
		perspectives.set_active(GameState.gaia_active)
	if hud:
		hud.refresh()
		hud.perspective.text = ("[Q] GAIA" if GameState.gaia_active else "CORPO")+" / "+str(data.get("region","RECIFE"))
		_update_interactions()

func operate_lift() -> bool:
	if not GameState.has_flag("recife_power"):
		hud.notify("Elevador sem energia. Restaure a bomba primeiro.")
		return false
	if lift_moving:
		hud.notify("Elevador em movimento. Aguarde na plataforma.")
		return false
	var nearest_stop := 0
	for index in range(lift_stops.size()):
		if absf(lift_stops[index]-player.position.y) < absf(lift_stops[nearest_stop]-player.position.y):
			nearest_stop = index
	if absf(lift.position.y+0.12-lift_stops[nearest_stop]) > 0.2:
		lift_target = lift_stops[nearest_stop]
	else:
		lift_target = lift_stops[(nearest_stop+1)%lift_stops.size()]
	lift_moving = true
	hud.notify("Elevador chamado. Entre no centro e aguarde o próximo nível.")
	return true

func _save_progress() -> void:
	for flag in StationJourney.INTRO_FLAGS + StationJourney.STORY_FLAGS:
		StationJourney.put(flag,1 if GameState.has_flag(flag) else 0)
	if player.is_on_floor() and not player.climbing:
		var point := player.position
		if absf(point.x-23.2)<0.8:point.x = 24.5
		StationJourney.store_checkpoint(point)
	if not StationJourney.save_game():hud.notify("Não foi possível salvar. Verifique o armazenamento do navegador.")

func play_sound(sound_id: String) -> void:
	var resolved := str(AudioDirector.ALIASES.get(sound_id,sound_id))
	audio.stream = AudioDirector.stream_for(resolved)
	if soundscape:soundscape.emit(resolved,player.global_position)

func set_muted(muted: bool) -> void:
	audio.volume_db = -80 if muted else -9
	perspectives.set_muted(muted)

func toggle_quality() -> void:
	environment.reduced = not environment.reduced
	get_viewport().scaling_3d_scale = 0.75 if environment.reduced else 1.0
	hud.notify("Perfil reduzido: renderização 75%, sem sombras." if environment.reduced else "Perfil normal: resolução 100%, sem sombras.")

func restart() -> void:
	hud.touch.release_all()
	SceneRouter.change_scene(scene_file_path)

func _nova_security(delta: float) -> void:
	var escaping := GameState.has_flag("nova_open")
	if escaping:
		drone.position.x = move_toward(drone.position.x,player.position.x,delta*2.7)
		drone.position.y = 1.8
	else:
		drone.position.x = 18.5+sin(elapsed*0.6)*2.4
		drone.position.y = 3.1
	if grace>0:return
	var detected := absf(player.position.x-drone.position.x)<0.85 and player.position.y<1.1 and player.position.y>-0.4
	suspicion = minf(1.5,suspicion+delta) if detected else maxf(0,suspicion-delta*2)
	if suspicion>0.45:hud.notify("NEXUS: inspeção. Suba à passarela ou siga para a saída!")
	if suspicion>=1.5:_capture()

func _capture() -> void:
	finished = true
	player.locked = true
	hud.touch.release_all()
	var fall := create_tween()
	fall.set_parallel(true)
	fall.tween_property(player.sprite,"rotation:z",-0.8,0.7)
	fall.tween_property(player.sprite,"modulate",Color(0.45,0.45,0.55,0.65),0.7)
	await fall.finished
	if not is_inside_tree():return
	hud._clear_modal("DERROTADO EM NOVA ÉDEN","O exército impediu sua fuga. Retome o confronto: soldados já derrotados permanecem no checkpoint. Aproxime-se para golpear e salte ou recue antes do ataque vermelho.")
	hud.button(hud.modal_box,"Reiniciar jornada",func():StationJourney.enter(false)).grab_focus()
	hud.button(hud.modal_box,"Retomar o combate",restart)
	hud.button(hud.modal_box,"Menu",menu)

func menu() -> void:
	hud.touch.release_all()
	SceneRouter.menu()

func _exit_tree() -> void:
	if GameState.changed.is_connected(_refresh):GameState.changed.disconnect(_refresh)
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null
