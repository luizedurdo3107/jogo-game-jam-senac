extends Node

signal volumes_changed
signal sound_emitted(sound_id: String, variant: int)

const SETTINGS_PATH := "user://audio_settings_v1.cfg"
const BUSES := ["Master","Music","Ambience","SFX","UI","Voice"]
const ALIASES := {"click":"install","gaia":"gaia_switch","gate":"gate","restore":"power_restore","exodus":"reserve"}
var levels := {"Master":0.45,"Music":0.35,"Ambience":0.7,"SFX":0.85,"UI":0.65,"Voice":0.85}
var catalog: Dictionary = {}
var cache: Dictionary = {}
var last_variant: Dictionary = {}
var last_event: Dictionary = {}
var event_counts: Dictionary = {}
var physical_players: Array[AudioStreamPlayer] = []
var physical_index := 0
var bed_levels := [-80.0,-80.0]
var physical_mix := 0.0
var digital_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var ui_players: Array[AudioStreamPlayer] = []
var active_scene: WeakRef
var active_scene_id := 0
var profile := ""
var gaia := false
var muted := false
var persistence_enabled := true
var settings_path := SETTINGS_PATH
var output_enabled := false
var volume_tween: Tween
var scene_tween: Tween
var filter_tween: Tween
var duck_requests: Dictionary = {}
var current_duck := ""
var missing_resources: Array[String] = []
var options: CanvasLayer
var shutting_down := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	output_enabled = DisplayServer.get_name()!="headless"
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/catalog.json"))
	levels.Master = GameState.volume
	load_preferences()
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.bus = "Ambience"
		player.volume_db = -80
		add_child(player)
		physical_players.append(player)
	digital_player = AudioStreamPlayer.new()
	digital_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	digital_player.bus = "Ambience"
	digital_player.stream = stream_for("gaia_layer")
	digital_player.volume_db = -80
	add_child(digital_player)
	music_player = AudioStreamPlayer.new()
	music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	music_player.bus = "Music"
	add_child(music_player)
	for index in range(5):
		var player := AudioStreamPlayer.new()
		player.bus = "UI"
		add_child(player)
		ui_players.append(player)
	_apply_volumes(false)
	get_tree().node_added.connect(_bind_ui)

func stream_for(sound_id: String, variant := 0) -> AudioStream:
	if not catalog.has(sound_id):return null
	var paths: Array = catalog[sound_id].paths
	var path := str(paths[posmod(variant,paths.size())])
	if not cache.has(path):
		if not ResourceLoader.exists(path):
			if not missing_resources.has(path):missing_resources.append(path)
			return null
		var stream: AudioStream = load(path)
		if stream is AudioStreamOggVorbis:stream.loop = bool(catalog[sound_id].loop)
		cache[path] = stream
	return cache[path]

func choose_variant(sound_id: String) -> int:
	var count: int = catalog.get(sound_id,{}).get("paths",[]).size()
	if count<=1:return 0
	var previous := int(last_variant.get(sound_id,-1))
	var choice := randi_range(0,count-1)
	if choice==previous:choice = (choice+1+randi_range(0,count-2))%count
	last_variant[sound_id] = choice
	return choice

func configure_player(player: Node, sound_id: String, variant := 0, variation := true) -> void:
	if not catalog.has(sound_id):return
	var definition: Dictionary = catalog[sound_id]
	player.stream = stream_for(sound_id,variant)
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.bus = definition.bus
	player.volume_db = float(definition.gain_db)+(randf_range(-0.9,0.9) if variation else 0)
	player.pitch_scale = 1+randf_range(-float(definition.pitch_variation),float(definition.pitch_variation)) if variation else 1.0

func record_event(sound_id: String, variant: int) -> void:
	event_counts[sound_id] = int(event_counts.get(sound_id,0))+1
	sound_emitted.emit(sound_id,variant)

func ui(sound_id := "ui_confirm") -> void:
	if shutting_down:return
	if not catalog.has(sound_id):return
	var now := Time.get_ticks_msec()
	var cooldown := maxf(float(catalog[sound_id].cooldown),0.7 if sound_id=="ui_notify" else 0.0)
	if now-int(last_event.get(sound_id,-10000))<int(1000*cooldown):return
	last_event[sound_id] = now
	var target: AudioStreamPlayer = ui_players[0]
	for player in ui_players:
		if not player.playing:
			target = player
			break
	var variant := choose_variant(sound_id)
	configure_player(target,sound_id,variant)
	if output_enabled and target.stream:target.play()
	record_event(sound_id,variant)

func _bind_ui(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func():ui("ui_cancel" if "Voltar" in str(node.get("text")) or "Cancelar" in str(node.get("text")) else "ui_confirm"))
		node.focus_entered.connect(func():ui("ui_hover"))
		node.mouse_entered.connect(func():ui("ui_hover"))

func attach_world(world: Node, region: String, actor: Node = null) -> Node:
	var existing := world.get_node_or_null("Soundscape")
	if existing:return existing
	var soundscape := Node.new()
	soundscape.name = "Soundscape"
	soundscape.set_script(preload("res://scripts/audio/world_soundscape.gd"))
	soundscape.region = region
	soundscape.actor = actor
	world.add_child(soundscape)
	return soundscape

func enter_region(owner: Node, region: String) -> void:
	active_scene = weakref(owner)
	active_scene_id = owner.get_instance_id()
	set_region(region)

func release_region(owner_id: int) -> void:
	release_duck(owner_id)
	if active_scene_id==owner_id:call_deferred("_release_region",owner_id)

func _release_region(owner_id: int) -> void:
	if active_scene_id!=owner_id:return
	active_scene_id = 0
	profile = ""
	set_gaia(false,false)
	if scene_tween:scene_tween.kill()
	scene_tween = create_tween().set_parallel(true)
	for index in range(2):scene_tween.tween_method(func(value: float):bed_levels[index]=value,float(bed_levels[index]),-80.0,0.65)

func set_region(region: String) -> void:
	if shutting_down:return
	if profile==region:return
	var file_id := "amb_"+str({"menu":"recife","ending_a":"recife_after","ending_b":"nexus"}.get(region,region))
	if not catalog.has(file_id):return
	profile = region
	if scene_tween:scene_tween.kill()
	var previous_index := physical_index
	physical_index = 1-physical_index
	var next_index := physical_index
	var next := physical_players[physical_index]
	configure_player(next,file_id,0,false)
	next.volume_db = -65
	bed_levels[next_index] = -65.0
	if output_enabled:next.play(randf()*3)
	scene_tween = create_tween().set_parallel(true)
	scene_tween.tween_method(func(value: float):bed_levels[previous_index]=value,float(bed_levels[previous_index]),-80.0,1.3)
	scene_tween.tween_method(func(value: float):bed_levels[next_index]=value,-65.0,-9.0 if region=="menu" else -2.0,1.3)
	var wet: float = {"lab":0.22,"water":0.18,"soil":0.1,"air":0.06,"nexus":0.15}.get(region.trim_suffix("_after"),0.06)
	for bus in ["Ambience","SFX"]:
		var reverb: AudioEffectReverb = AudioServer.get_bus_effect(AudioServer.get_bus_index(bus),1)
		reverb.wet = wet

func set_gaia(enabled: bool, transition := true) -> void:
	if shutting_down:return
	var changed := gaia!=enabled
	if not changed:return
	gaia = enabled
	if filter_tween:filter_tween.kill()
	filter_tween = create_tween().set_parallel(true)
	var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index("Ambience"),0)
	filter_tween.tween_property(filter,"cutoff_hz",4600.0 if enabled else 16000.0,0.32)
	filter_tween.tween_property(digital_player,"volume_db",-8.0 if enabled else -80.0,0.4)
	filter_tween.tween_property(self,"physical_mix",-5.0 if enabled else 0.0,0.4)
	if enabled and not digital_player.playing and output_enabled:digital_player.play()
	_apply_volumes()
	if changed and transition:ui("gaia_switch")

func set_volume(bus: String, amount: float, persist := true) -> void:
	if bus not in BUSES or not is_finite(amount):return
	levels[bus] = clampf(amount,0,1)
	GameState.volume = float(levels.Master)
	_apply_volumes()
	if persist and persistence_enabled:save_preferences()
	volumes_changed.emit()

func set_muted(enabled: bool) -> void:
	muted = enabled
	_apply_volumes(false)
	volumes_changed.emit()

func request_duck(owner: Node, kind: String) -> void:
	var key := owner.get_instance_id()
	if kind.is_empty():duck_requests.erase(key)
	else:duck_requests[key] = {"owner":weakref(owner),"kind":kind}
	_update_duck()

func release_duck(owner_id: int) -> void:
	duck_requests.erase(owner_id)
	_update_duck()

func _update_duck() -> void:
	var context := "paused" if get_tree().paused else ""
	for key in duck_requests.keys():
		var entry: Dictionary = duck_requests[key]
		if not entry.owner.get_ref():
			duck_requests.erase(key)
			continue
		if entry.kind=="paused":context = "paused"
		elif context.is_empty():context = "dialogue"
	if current_duck!=context:
		current_duck = context
		_apply_volumes()

func _apply_volumes(smooth := true) -> void:
	if volume_tween:volume_tween.kill()
	volume_tween = create_tween().set_parallel(true) if smooth else null
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index<0:continue
		var amount := float(levels[bus])
		var attenuation := 0.0
		if gaia and bus=="SFX":attenuation -= 3
		if current_duck!="" and bus in ["Music","Ambience","SFX"]:
			attenuation -= (10.0 if bus=="Music" else 8.0) if current_duck=="paused" else (7.0 if bus=="Music" else 3.0)
		var target := linear_to_db(maxf(0.0001,amount))+attenuation
		AudioServer.set_bus_mute(index,amount<=0 or bus=="Master" and muted)
		if smooth:volume_tween.tween_method(func(value: float):AudioServer.set_bus_volume_db(index,value),AudioServer.get_bus_volume_db(index),target,0.22)
		else:AudioServer.set_bus_volume_db(index,target)

func save_preferences() -> bool:
	if not persistence_enabled:return true
	var config := ConfigFile.new()
	config.set_value("audio","version",1)
	for bus in BUSES:config.set_value("volumes",bus,levels[bus])
	var temporary := settings_path+".tmp"
	if config.save(temporary)!=OK:return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(settings_path))==OK

func load_preferences() -> bool:
	var config := ConfigFile.new()
	if config.load(settings_path)!=OK or config.get_value("audio","version",0)!=1:return false
	var loaded: Dictionary = {}
	for bus in BUSES:
		var value: Variant = config.get_value("volumes",bus,null)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>1:return false
		loaded[bus] = float(value)
	levels = loaded
	GameState.volume = float(levels.Master)
	if is_node_ready():_apply_volumes(false)
	return true

func open_settings(owner: Node) -> void:
	if is_instance_valid(options):return
	options = CanvasLayer.new()
	options.set_script(preload("res://scripts/audio/audio_options.gd"))
	owner.add_child(options)

func quit_game() -> void:
	if shutting_down:return
	if OS.has_feature("web"):
		get_tree().paused = false
		if StationJourney.active:StationJourney.leave()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return
	shutting_down = true
	for tween in [volume_tween,scene_tween,filter_tween]:
		if tween:tween.kill()
	for soundscape in get_tree().get_nodes_in_group("audio_worlds"):soundscape.stop_all()
	for player in physical_players+ui_players+[digital_player,music_player]:
		player.stop()
		player.stream = null
	await get_tree().create_timer(0.2,true).timeout
	get_tree().quit()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:quit_game()

func _process(_delta: float) -> void:
	_update_duck()
	for index in range(physical_players.size()):
		physical_players[index].volume_db = float(bed_levels[index])+physical_mix
		if bed_levels[index]<= -79 and physical_players[index].playing:physical_players[index].stop()
	if not gaia and digital_player.volume_db<= -79 and digital_player.playing:digital_player.stop()

func _exit_tree() -> void:
	for tween in [volume_tween,scene_tween,filter_tween]:
		if tween:tween.kill()
	for player in physical_players+ui_players+[digital_player,music_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	cache.clear()
	duck_requests.clear()
