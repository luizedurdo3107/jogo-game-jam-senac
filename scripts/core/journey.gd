extends Node

signal changed

const SAVE_PATH := "user://last_signal_restored_v6.json"
const LEGACY_PATHS := ["user://last_signal_restored_v5.json","user://last_signal_restored_v4.json","user://last_signal_short_v3.json","user://last_signal_mobile_v2.json","user://stations_25d_v1.json"]
const SCENES := {"cinematic":"res://scenes/story/intro.tscn","nova_eden":"res://scenes/regions/nova_eden.tscn","laboratory":"res://scenes/regions/laboratory.tscn","boss":"res://scenes/regions/gaia_core.tscn","recife":"res://scenes/regions/recife.tscn","water":"res://scenes/regions/water.tscn","soil":"res://scenes/regions/soil.tscn","air":"res://scenes/regions/air.tscn","nexus":"res://scenes/regions/nexus.tscn","ending":"res://scenes/regions/epilogue.tscn"}
const INTRO_FLAGS := ["recife_awake","recife_scan","recife_cell","recife_power","recife_authorized","recife_gate","recife_archive","recife_drone"]
const STORY_FLAGS := ["nova_contact","nova_module","nova_credential","nova_power","nova_open","nova_escaped","ruins_contact","ruins_water","ruins_gate","ruins_memory","ruins_drone"]
const ORDER := ["water","soil","air"]
const NOVA_LIMITS := {"nova_armory":3,"nova_weapon":1,"nova_difficulty":1,"departure_started":1,"departure_security":7,"departure_legacy_clear":1}
const LIMITS := {"nova_security":7,"nova_legacy_passage":1,"legacy_departure":1,"intro_seen":1,"nova_contact":1,"nova_module":1,"nova_credential":1,"nova_power":1,"nova_open":1,"nova_escaped":1,"ruins_contact":1,"ruins_water":1,"ruins_gate":1,"ruins_memory":1,"ruins_drone":1,"final_destination":2,"boss_mask":7,"boss_done":1,"recife_awake":1,"recife_scan":1,"recife_cell":1,"recife_power":1,"recife_authorized":1,"recife_gate":1,"recife_archive":1,"recife_drone":1,"nexus_voss":1,"nexus_scan":1,"nexus_locks":1,"nexus_authorized":1,"nexus_open":1,"nexus_confirmed":1,"water_route":2,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1,"water_memory":1,"soil_filter":2,"soil_mask":15,"soil_humidity":2,"soil_temperature":2,"soil_authorized":1,"soil_irrigation":1,"soil_open":1,"soil_memory":1,"air_scan":1,"air_team":1,"air_module":2,"air_sequence":3,"air_filter":2,"air_drone":1,"air_open":1,"air_memory":1}

var station := "water"
var stage := "cinematic"
var values: Dictionary = {}
var choices := {"water":"PENDING","soil":"PENDING","air":"PENDING"}
var checkpoints: Dictionary = {}
var persistence_enabled := true
var save_path := SAVE_PATH
var active := false

func reset() -> void:
	station = "water"
	stage = "cinematic"
	values.clear()
	choices = {"water":"PENDING","soil":"PENDING","air":"PENDING"}
	checkpoints.clear()
	changed.emit()

func value(key: String) -> int:
	return int(values.get(key,0))

func put(key: String, number: int) -> void:
	if NOVA_LIMITS.has(key):
		values[key] = clampi(number,0,NOVA_LIMITS[key])
	elif LIMITS.has(key):
		values[key] = clampi(number,0,LIMITS[key])

func checkpoint() -> Vector3:
	var point: Array = checkpoints.get(region(),[2.0,0.05])
	return Vector3(point[0],point[1],0)

func store_checkpoint(point: Vector3) -> void:
	checkpoints[region()] = [point.x,point.y]

func snapshot() -> Dictionary:
	return {"version":6,"station":station,"stage":stage,"values":values.duplicate(),"choices":choices.duplicate(),"checkpoints":checkpoints.duplicate(true)}

func validate(data: Variant) -> bool:
	if not data is Dictionary or data.get("version",0)!=6 or data.get("station","") not in ORDER or data.get("stage","") not in ["cinematic","nova","ruins","intro","stations","nexus","boss","ending"]:return false
	if not data.get("values") is Dictionary or not data.get("choices") is Dictionary or not data.get("checkpoints") is Dictionary:return false
	var limits := LIMITS.merged(NOVA_LIMITS)
	for key in data.values:
		var number: Variant = data.values[key]
		if not limits.has(key) or not (number is int or number is float) or not is_finite(float(number)) or float(number)!=floorf(float(number)) or number<0 or number>limits[key]:return false
	var legacy := preload("res://scripts/core/legacy_journey_save.gd").new()
	var technical: Dictionary = data.duplicate(true)
	technical.version = 2
	technical.stage = "intro" if data.stage in ["cinematic","nova","ruins","intro"] else ("nexus" if data.stage in ["nexus","boss","ending"] else "stations")
	for key in data.values:
		if not legacy.LIMITS.has(key):technical.values.erase(key)
	technical.checkpoints.clear()
	if not legacy.validate(technical):return false
	for region_id in data.checkpoints:
		var point: Variant = data.checkpoints[region_id]
		if region_id not in ["nova_eden","recife","laboratory","water","soil","air","nexus","boss"] or not point is Array or point.size()!=2:return false
		for coordinate in point:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):return false
		if point[0]<0 or point[0]>36 or point[1]<-3 or point[1]>8:return false
	for pair in [["nova_escaped","nova_open"],["ruins_water","ruins_contact"],["ruins_gate","ruins_water"]]:
		if int(data.values.get(pair[0],0))==1 and int(data.values.get(pair[1],0))!=1:return false
	if int(data.values.get("nova_open",0))==1 and int(data.values.get("nova_security",0))!=7 and int(data.values.get("nova_legacy_passage",0))!=1:return false
	if int(data.values.get("nova_weapon",0))==1 and int(data.values.get("nova_armory",0))!=3:return false
	if int(data.values.get("nova_security",0))==7 and int(data.values.get("nova_open",0))!=1:return false
	if int(data.values.get("nova_legacy_passage",0))==1 and int(data.values.get("nova_open",0))!=1:return false
	var destination := int(data.values.get("final_destination",0))
	var boss_mask := int(data.values.get("boss_mask",0))
	if boss_mask not in [0,1,3,7] or (boss_mask>0 and destination!=2):return false
	if destination>0 and data.stage not in ["boss","ending"]:return false
	if data.stage in ["boss","ending"] and (destination==0 or int(data.values.get("nexus_open",0))!=1):return false
	if data.stage in ["boss","ending"] and int(data.values.get("nexus_confirmed",0))!=1:return false
	if data.stage=="boss" and destination!=2:return false
	if int(data.values.get("boss_done",0))==1 and (int(data.values.get("boss_mask",0))!=7 or destination!=2):return false
	if int(data.values.get("legacy_departure",0))==1 and (data.stage!="ending" or destination!=2):return false
	var departure_started := int(data.values.get("departure_started",0))
	var departure_security := int(data.values.get("departure_security",0))
	if (departure_started==1 or departure_security>0 or int(data.values.get("departure_legacy_clear",0))==1) and (destination!=2 or data.stage not in ["boss","ending"]):return false
	if departure_security>0 and departure_started!=1:return false
	if int(data.values.get("departure_legacy_clear",0))==1 and departure_security!=7:return false
	if data.stage=="ending" and departure_started==1 and departure_security!=7:return false
	if data.stage=="ending" and destination==2 and int(data.values.get("boss_done",0))!=1 and int(data.values.get("legacy_departure",0))!=1:return false
	return true

func migrate(data: Variant) -> Dictionary:
	var previous := preload("res://scripts/core/restored_v5_validator.gd").new()
	if previous.validate(data):return _upgrade_restored(data)
	var restored := preload("res://scripts/core/restored_v4_validator.gd").new()
	if restored.validate(data):
		var revised: Dictionary = data.duplicate(true)
		revised.version = 5
		revised.values.erase("boss_mask")
		revised.values.erase("boss_done")
		revised.checkpoints.erase("boss")
		if data.stage=="boss":revised.stage = "ending"
		if data.stage=="ending" and int(data.values.get("final_destination",0))==2:revised.values.legacy_departure = 1
		return _upgrade_restored(revised)
	var short_validator := preload("res://scripts/core/short_save_validator.gd").new()
	var legacy := preload("res://scripts/core/legacy_journey_save.gd").new()
	if not short_validator.validate(data) and not legacy.validate(data):return {}
	var converted: Dictionary = data.duplicate(true)
	converted.version = 6
	converted.choices = {"water":data.choices.water,"soil":data.choices.get("soil","PENDING"),"air":data.choices.get("air","PENDING")}
	converted.values.erase("signal_sent")
	converted.values.erase("nexus_confirmed")
	converted.values.intro_seen = 1
	if data.stage=="intro":
		converted.stage = "intro"
		if converted.checkpoints.has("recife"):
			converted.checkpoints.laboratory = converted.checkpoints.recife
			converted.checkpoints.erase("recife")
	elif data.stage=="ending":
		converted.stage = "stations" if data.version==3 else "nexus"
	converted.station = "water" if data.version==3 else data.station
	return converted if validate(converted) else {}

func _upgrade_restored(data: Dictionary) -> Dictionary:
	var converted := data.duplicate(true)
	converted.version = 6
	if int(converted.values.get("nova_open",0))==1:converted.values.nova_legacy_passage = 1
	if converted.stage=="nova" and int(converted.values.get("nova_open",0))==0:
		for key in ["nova_module","nova_credential","nova_power"]:converted.values.erase(key)
		converted.checkpoints.erase("nova_eden")
	return converted if validate(converted) else {}

func read_save() -> Dictionary:
	var paths: Array = [save_path]
	if save_path==SAVE_PATH and not FileAccess.file_exists(save_path):paths.append_array(LEGACY_PATHS)
	for path in paths:
		if not FileAccess.file_exists(path):continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path))!=OK:return {}
		if validate(parser.data):return parser.data
		return migrate(parser.data)
	return {}

func load_game() -> bool:
	var data := read_save()
	if data.is_empty():
		return false
	station = data.station
	stage = data.stage
	values.clear()
	for key in data.values:
		values[key] = int(data.values[key])
	choices = data.choices.duplicate()
	checkpoints = data.checkpoints.duplicate(true)
	changed.emit()
	return true

func save_game() -> bool:
	changed.emit()
	if not persistence_enabled:
		return true
	var data := snapshot()
	if not validate(data):
		return false
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data,"",true,true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error!=OK:return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))==OK

func region() -> String:
	return str({"cinematic":"cinematic","nova":"nova_eden","ruins":"recife","intro":"laboratory","nexus":"nexus","boss":"boss","ending":"ending"}.get(stage,station))

func enter(continuing := true) -> void:
	if not continuing or not load_game():
		reset()
	active = true
	GameState.reset()
	GameState.persistence_enabled = false
	GameState.gaia_unlocked = stage in ["stations","nexus","boss","ending"] or value("recife_awake")==1
	GameState.station_choices = choices.duplicate()
	for flag in INTRO_FLAGS:
		if value(flag)==1:GameState.flags[flag] = true
	if value("recife_cell")==1 and value("recife_power")==0:
		GameState.inventory.append("recife_cell")
	save_game()
	_open_current()

func _open_current() -> void:
	GameState.gaia_active = false
	SceneRouter.last_requested = "ending" if stage=="ending" else region()
	SceneRouter.change_scene(SCENES[SceneRouter.last_requested])

func start_stations() -> void:
	if stage=="intro":advance_story()

func open_station(destination: String) -> bool:
	if destination not in ORDER:return false
	if destination!="water" and choices.water=="PENDING":return false
	if destination=="air" and choices.soil=="PENDING":return false
	var previous_stage := stage
	var previous_station := station
	stage = "stations"
	station = destination
	if not save_game():
		stage = previous_stage
		station = previous_station
		return false
	_open_current()
	return true

func decide(choice: String) -> bool:
	if stage!="stations" or choice not in ["RESTORE","EXODUS"] or value(station+"_open")!=1 or choices[station]!="PENDING":return false
	choices[station] = choice
	if not save_game():
		choices[station] = "PENDING"
		return false
	GameState.station_choices = choices.duplicate()
	return true

func advance() -> bool:
	if stage!="stations" or choices[station]=="PENDING":return false
	var next_index := ORDER.find(station)+1
	if next_index<ORDER.size():return open_station(ORDER[next_index])
	return enter_nexus()

func enter_nexus() -> bool:
	if stage!="stations" or choices.values().has("PENDING"):return false
	stage = "nexus"
	if not save_game():
		stage = "stations"
		return false
	_open_current()
	return true

func ending() -> String:
	return str({1:"ending_a",2:"ending_b"}.get(value("final_destination"),""))

func choose_destination(destination: String) -> bool:
	if stage!="nexus" or value("nexus_open")!=1 or choices.values().has("PENDING") or destination not in ["EARTH","MARS"]:return false
	var previous := snapshot()
	put("final_destination",1 if destination=="EARTH" else 2)
	put("nexus_confirmed",1)
	if destination=="MARS":put("departure_started",1)
	stage = "ending" if destination=="EARTH" else "boss"
	if not save_game():
		stage = previous.stage
		values = previous.values
		return false
	_open_current()
	return true

func complete_boss() -> bool:
	if stage!="boss" or value("final_destination")!=2 or value("boss_mask")!=7:return false
	if value("departure_started")==1 and value("departure_security")!=7:return false
	put("boss_done",1)
	stage = "ending"
	if not save_game():
		stage = "boss"
		values.erase("boss_done")
		return false
	_open_current()
	return true

func finish_intro() -> void:
	if stage!="cinematic":return
	put("intro_seen",1)
	stage = "nova"
	if not save_game():
		stage = "cinematic"
		return
	_open_current()

func advance_story() -> bool:
	var required := str({"nova":"nova_escaped","ruins":"ruins_gate","intro":"recife_gate"}.get(stage,""))
	if required.is_empty() or value(required)!=1:return false
	var previous := stage
	stage = str({"nova":"ruins","ruins":"intro","intro":"stations"}[stage])
	if not save_game():
		stage = previous
		return false
	_open_current()
	return true

func leave() -> void:
	active = false
	GameState.gaia_active = false
	GameState.input_locked = false
