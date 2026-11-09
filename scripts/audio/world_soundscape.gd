extends Node

var region := "recife"
var actor: Node
var machines: Dictionary = {}
var shots: Array[Node] = []
var previous_lift := false
var previous_restored := false
var timer := 0.0
var current_profile := ""
var recovery_profile := ""
var previous_alert := false
var scene_id := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_worlds")
	scene_id = get_instance_id()
	if actor:
		if actor is Node3D:
			var listener := AudioListener3D.new()
			listener.position.y = 1.0
			actor.add_child(listener)
			listener.make_current()
		elif actor is Node2D:
			var listener := AudioListener2D.new()
			listener.position.y = -20
			actor.add_child(listener)
			listener.make_current()
		var locomotion := Node.new()
		locomotion.set_script(preload("res://scripts/audio/locomotion_audio.gd"))
		locomotion.soundscape = self
		actor.add_child(locomotion)
	current_profile = resolve_profile()
	AudioDirector.enter_region(self,current_profile)
	AudioDirector.set_gaia(GameState.gaia_active if actor else false,false)
	sync_machines()

func resolve_profile() -> String:
	if region=="nova_eden":return "nova"
	if region=="ruinas_laboratorio":return "lab" if actor and actor.position.x>=1070 and actor.position.y<620 else "recife"
	if region=="estacoes_ambientais":return "water" if actor.position.x<1480 else ("soil" if actor.position.x<2800 else "air")
	if region=="complexo_nexus":return "nexus"
	return region

func _process(delta: float) -> void:
	if not is_instance_valid(get_parent()):return
	var desired := resolve_profile()
	if desired!=current_profile:
		current_profile = desired
		AudioDirector.enter_region(self,desired)
	var bed_profile := current_profile+"_after" if current_profile in ["water","soil","air"] and restored() else current_profile
	if bed_profile!=recovery_profile:
		recovery_profile = bed_profile
		AudioDirector.set_region(bed_profile)
	if actor and AudioDirector.gaia!=GameState.gaia_active:AudioDirector.set_gaia(GameState.gaia_active)
	var hud: Variant = get_parent().get("hud")
	var context := ""
	if hud and is_instance_valid(hud):
		if hud.get("paused")==true:context = "paused"
		elif hud.get("modal_open")==true:context = "paused" if "PAUSA" in str(hud.modal_box.get_child(0).text) else "dialogue"
		elif hud.get("dialogue_visible")==true:context = "dialogue"
	AudioDirector.request_duck(self,context)
	timer += delta
	if timer>=0.08:
		timer = 0
		sync_machines()

func state_value(key: String) -> int:
	var world := get_parent()
	if world.get("station_id")!=null:return int(world.journey.value(key))
	var flags := {"water_pump":"water_power","soil_irrigation":"soil_filter","air_module":"air_power","air_sequence":"air_vents_done"}
	if world.get("data")!=null and world.get("station_id")==null:
		if key=="water_pump":return 1 if current_profile=="recife" and GameState.has_flag("recife_power") else 0
	if flags.has(key):return 1 if GameState.has_flag(flags[key]) else 0
	return 0

func restored() -> bool:
	var world := get_parent()
	if world.get("station_id")!=null:return world.journey.choices.get(current_profile,"PENDING")=="RESTORE"
	return GameState.station_choices.get("water" if world.get("data")!=null else current_profile,"PENDING")=="RESTORE"

func sync_machines() -> void:
	if not actor:return
	var world := get_parent()
	var is_3d := actor is Node3D
	var at_water: Variant = Vector3(20,0.9,-1) if is_3d else Vector2(435,390)
	var at_soil: Variant = Vector3(23,0.6,-1) if is_3d else Vector2(2250,390)
	var at_air: Variant = Vector3(18,5.6,-2) if is_3d else Vector2(3530,300)
	if not is_3d:
		for equipment in [["water_power","pump"],["soil_filter","irrigation"],["air_power","fan"]]:
			var object: Node = world.objects.get(equipment[0])
			if object:
				if equipment[1]=="pump":at_water = object.global_position
				elif equipment[1]=="irrigation":at_soil = object.global_position
				else:at_air = object.global_position
	set_machine("pump",(current_profile=="water" or world.get("data")!=null) and state_value("water_pump")==1,"pump_steady" if restored() else "pump_rough",at_water)
	set_machine("irrigation",current_profile=="soil" and state_value("soil_irrigation")==1,"irrigation",at_soil)
	set_machine("fan",current_profile=="air" and state_value("air_module")>0 and state_value("air_sequence")>0,"fan_steady" if restored() else "fan_rough",at_air)
	if world.get("lift") is Node3D:
		var moving: bool = world.lift_moving and not world.hud.modal_open and not get_tree().paused
		set_machine("lift",moving,"lift_motor",world.lift.position+Vector3(0,0.5,0))
		if moving!=previous_lift:
			emit("lift_start" if moving else "lift_stop",world.lift.position)
			previous_lift = moving
	elif world.get("elevators") is Dictionary:
		for key in world.elevators:
			var lift: Node2D = world.elevators[key]
			var moving: bool = lift.moving and not get_tree().paused
			var machine_key := "lift_"+str(key)
			var previously: bool = machines.get(machine_key,{}).get("active",false)
			set_machine(machine_key,moving,"lift_motor",lift.position)
			if previously!=moving:emit("lift_start" if moving else "lift_stop",lift.position)
	if world.get("drone") is Node3D or world.get("drone") is Node2D:
		var drone: Node = world.drone
		set_machine("drone",true,"drone_rotor",drone.position)
		var alert: bool = float(world.get("suspicion"))>0.7 if is_3d else drone.state=="alert"
		if alert and not previous_alert:emit("drone_alert",drone.position)
		previous_alert = alert
	if restored() and not previous_restored:
		previous_restored = true
		if current_profile=="soil":emit("irrigation_start",at_soil)
		elif current_profile=="air":emit("fan_start",at_air)

func make_player(at: Variant) -> Node:
	var player: Node
	if at is Vector3:
		var spatial := AudioStreamPlayer3D.new()
		spatial.unit_size = 6.0
		spatial.max_distance = 30.0
		spatial.panning_strength = 0.35
		spatial.attenuation_filter_cutoff_hz = 11000
		player = spatial
	elif at is Vector2:
		var spatial := AudioStreamPlayer2D.new()
		spatial.max_distance = 1100
		spatial.panning_strength = 0.3
		player = spatial
	else:player = AudioStreamPlayer.new()
	add_child(player)
	if at is Vector2 or at is Vector3:player.global_position = at
	return player

func set_machine(key: String, active: bool, sound_id: String, at: Variant) -> void:
	if not machines.has(key):
		if not active:return
		machines[key] = {"player":make_player(at),"sound":"","active":false,"tween":null}
	var machine: Dictionary = machines[key]
	var player: Node = machine.player
	if at is Vector3 or at is Vector2:player.global_position = at
	if machine.active==active and machine.sound==sound_id:return
	if machine.tween:machine.tween.kill()
	var changed_sound: bool = machine.sound!=sound_id
	machine.active = active
	machine.sound = sound_id
	if changed_sound:
		var previous: Node = player
		if previous.stream:
			var release := create_tween()
			release.tween_property(previous,"volume_db",-65.0,0.45)
			release.tween_callback(func():previous.stop();previous.stream=null;previous.queue_free())
			player = make_player(at)
			machine.player = player
		AudioDirector.configure_player(player,sound_id,0,false)
		player.volume_db = -65
	if active:
		if AudioDirector.output_enabled and not player.playing:player.play()
		AudioDirector.record_event("loop_"+key,0)
	var target: float = AudioDirector.catalog[sound_id].gain_db if active else -65.0
	var fade := create_tween()
	fade.tween_property(player,"volume_db",target,0.85 if active else 0.35)
	if not active:fade.tween_callback(player.stop)
	machine.tween = fade

func emit(sound_id: String, at: Variant = null, gain_db := 0.0) -> Node:
	if not AudioDirector.catalog.has(sound_id):return null
	var player: Node
	for candidate in shots:
		if is_instance_valid(candidate) and not candidate.playing and ((at is Vector3 and candidate is AudioStreamPlayer3D) or (at is Vector2 and candidate is AudioStreamPlayer2D) or (at==null and candidate is AudioStreamPlayer)):
			player = candidate
			break
	if not player:
		if shots.size()>=14:return null
		player = make_player(at)
		shots.append(player)
	if at is Vector3 and player is AudioStreamPlayer3D or at is Vector2 and player is AudioStreamPlayer2D:player.global_position = at
	var variant := AudioDirector.choose_variant(sound_id)
	AudioDirector.configure_player(player,sound_id,variant)
	player.volume_db += gain_db
	if AudioDirector.output_enabled and player.stream:player.play()
	AudioDirector.record_event(sound_id,variant)
	return player

func interaction(object_id: String, kind: String, digital: bool, at: Variant) -> void:
	var sound_id := "circuit" if digital else "install"
	if digital:
		if "memory" in object_id or "archive" in object_id or "hidden" in object_id:sound_id = "archive"
		elif "drain" in object_id:sound_id = "pressure"
		elif "scan" in object_id or "authorize" in object_id:sound_id = "scan"
	else:
		if object_id=="soil_filter":sound_id = "object_move"
		elif object_id=="terminal":sound_id = "gaia_switch"
		elif kind=="valve" or "valve" in object_id or "humidity" in object_id:sound_id = "valve"
		elif kind=="door" or "door" in object_id or object_id=="gate":sound_id = "gate" if current_profile=="water" else ("capsule" if current_profile=="soil" else "door")
		elif object_id in ["module","cell","filter","lab_cell","water_cell","soil_cartridge","air_cell"]:sound_id = "pickup"
		elif "irrigate" in object_id:sound_id = "irrigation_start"
		elif object_id=="pump":sound_id = "pump_start"
		elif kind in ["npc","decision","lift","exit","dialogue"]:return
	emit(sound_id,at)

func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D or child is AudioStreamPlayer3D:
			child.stop()
			child.stream = null

func _exit_tree() -> void:
	AudioDirector.release_region(scene_id)
	stop_all()
