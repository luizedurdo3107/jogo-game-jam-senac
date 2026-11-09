extends Node

signal changed

const SAVE_PATH := "user://last_signal_mobile_v2.json"
const LEGACY_PATH := "user://stations_25d_v1.json"
const SCENES := {"recife":"res://scenes/regions/recife.tscn","water":"res://scenes/regions/water.tscn","soil":"res://scenes/regions/soil.tscn","air":"res://scenes/regions/air.tscn","nexus":"res://scenes/regions/nexus.tscn","ending":"res://scenes/regions/epilogue.tscn"}
const INTRO_FLAGS := ["recife_awake","recife_scan","recife_cell","recife_power","recife_authorized","recife_gate","recife_archive","recife_drone"]
const ORDER := ["water","soil","air"]
const LIMITS := {"recife_awake":1,"recife_scan":1,"recife_cell":1,"recife_power":1,"recife_authorized":1,"recife_gate":1,"recife_archive":1,"recife_drone":1,"nexus_voss":1,"nexus_scan":1,"nexus_locks":1,"nexus_authorized":1,"nexus_open":1,"nexus_confirmed":1,"water_route":2,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1,"water_memory":1,"soil_filter":2,"soil_mask":15,"soil_humidity":2,"soil_temperature":2,"soil_authorized":1,"soil_irrigation":1,"soil_open":1,"soil_memory":1,"air_scan":1,"air_team":1,"air_module":2,"air_sequence":3,"air_filter":2,"air_drone":1,"air_open":1,"air_memory":1}

var station := "water"
var stage := "intro"
var values: Dictionary = {}
var choices := {"water":"PENDING","soil":"PENDING","air":"PENDING"}
var checkpoints: Dictionary = {}
var persistence_enabled := true
var save_path := SAVE_PATH
var active := false

func reset() -> void:
	station = "water"
	stage = "intro"
	values.clear()
	choices = {"water":"PENDING","soil":"PENDING","air":"PENDING"}
	checkpoints.clear()
	changed.emit()

func value(key: String) -> int:
	return int(values.get(key,0))

func put(key: String, number: int) -> void:
	if LIMITS.has(key):
		values[key] = clampi(number,0,LIMITS[key])

func checkpoint() -> Vector3:
	var point: Array = checkpoints.get(region(),[2.0,0.05])
	return Vector3(point[0],point[1],0)

func store_checkpoint(point: Vector3) -> void:
	checkpoints[region()] = [point.x,point.y]

func snapshot() -> Dictionary:
	return {"version":2,"station":station,"stage":stage,"values":values.duplicate(),"choices":choices.duplicate(),"checkpoints":checkpoints.duplicate(true)}

func validate(data: Variant) -> bool:
	if not data is Dictionary or (data.get("version",0)!=1 and data.get("version",0)!=2) or data.get("station","") not in ORDER or data.get("stage","") not in ["intro","stations","nexus","ending"]:
		return false
	if not data.get("values") is Dictionary or not data.get("choices") is Dictionary or not data.get("checkpoints") is Dictionary:
		return false
	if data.choices.size()!=ORDER.size():return false
	for key in data.values:
		var number: Variant = data.values[key]
		if not LIMITS.has(key) or not (number is int or number is float) or not is_finite(float(number)) or float(number)!=floorf(float(number)) or number<0 or number>LIMITS[key]:
			return false
	for region in ORDER:
		if data.choices.get(region,"") not in ["PENDING","RESTORE","EXODUS"]:
			return false
		if data.choices[region]!="PENDING" and int(data.values.get(region+"_open",0))!=1:
			return false
	for region in data.checkpoints:
		var point: Variant = data.checkpoints[region]
		if region not in ["recife","water","soil","air","nexus"] or not point is Array or point.size()!=2:
			return false
		for coordinate in point:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
				return false
		if point[0]<0 or point[0]>36 or point[1]<-3 or point[1]>8:
			return false
	if data.station!="water" and data.choices.water=="PENDING":
		return false
	if data.station=="air" and data.choices.soil=="PENDING":
		return false
	if data.stage in ["nexus","ending"] and data.choices.values().has("PENDING"):
		return false
	var technical: Dictionary = data.values
	if int(data.version)==1 and data.stage not in ["stations","nexus"]:return false
	if int(data.version)==2:
		for pair in [["recife_scan","recife_awake"],["recife_cell","recife_scan"],["recife_power","recife_cell"],["recife_authorized","recife_power"],["recife_gate","recife_authorized"],["nexus_scan","nexus_voss"],["nexus_locks","nexus_scan"],["nexus_authorized","nexus_locks"],["nexus_open","nexus_authorized"],["nexus_confirmed","nexus_open"]]:
			if int(technical.get(pair[0],0))==1 and int(technical.get(pair[1],0))!=1:return false
		if data.stage=="intro" and (data.station!="water" or data.choices.values().count("PENDING")!=3):return false
		if data.stage=="ending" and int(technical.get("nexus_confirmed",0))!=1:return false
	if int(technical.get("water_module",0))>0 and int(technical.get("water_drained",0))!=1:return false
	if int(technical.get("water_authorized",0))==1 and (int(technical.get("water_module",0))!=2 or int(technical.get("water_route",0))!=1 or int(technical.get("water_a",0))*20+int(technical.get("water_b",0))*10!=60):return false
	for pair in [["water_pump","water_authorized"],["water_open","water_pump"],["soil_irrigation","soil_authorized"],["soil_open","soil_irrigation"]]:
		if int(technical.get(pair[0],0))==1 and int(technical.get(pair[1],0))!=1:return false
	if int(technical.get("soil_authorized",0))==1 and (int(technical.get("soil_filter",0))!=2 or int(technical.get("soil_mask",0))!=10 or int(technical.get("soil_humidity",0))!=1 or int(technical.get("soil_temperature",0))!=1):return false
	if int(technical.get("air_team",0))==1 and int(technical.get("air_module",0))!=2:return false
	if int(technical.get("air_sequence",0))>0 and (int(technical.get("air_module",0))!=2 or int(technical.get("air_scan",0))!=1):return false
	if int(technical.get("air_drone",0))==1 and (int(technical.get("air_team",0))!=1 or int(technical.get("air_scan",0))!=1):return false
	if int(technical.get("air_open",0))==1 and (int(technical.get("air_sequence",0))!=3 or int(technical.get("air_filter",0))!=1 or int(technical.get("air_team",0))!=1):return false
	return true

func read_save() -> Dictionary:
	var path := save_path
	if path==SAVE_PATH and not FileAccess.file_exists(path):
		path = LEGACY_PATH
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not validate(parser.data):
		return {}
	var data: Dictionary = parser.data
	data.version = 2
	return data

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
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))==OK

func region() -> String:
	return "recife" if stage=="intro" else ("nexus" if stage in ["nexus","ending"] else station)

func enter(continuing := true) -> void:
	if not continuing or not load_game():
		reset()
	active = true
	GameState.reset()
	GameState.persistence_enabled = false
	GameState.gaia_unlocked = stage!="intro" or value("recife_awake")==1
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
	if not SceneRouter.test_mode:
		get_tree().change_scene_to_file(SCENES[SceneRouter.last_requested])

func start_stations() -> void:
	if value("recife_gate")!=1:return
	stage = "stations"
	station = "water"
	save_game()
	_open_current()

func open_station(destination: String) -> void:
	if destination not in ORDER:return
	if destination!="water" and choices.water=="PENDING":return
	if destination=="air" and choices.soil=="PENDING":return
	stage = "stations"
	station = destination
	save_game()
	_open_current()

func decide(choice: String) -> bool:
	if choice not in ["RESTORE","EXODUS"] or value(station+"_open")!=1 or choices[station]!="PENDING":return false
	choices[station] = choice
	GameState.station_choices = choices.duplicate()
	save_game()
	return true

func advance() -> void:
	if choices[station]=="PENDING":return
	var next_index := ORDER.find(station)+1
	if next_index<ORDER.size():open_station(ORDER[next_index])
	else:enter_nexus()

func enter_nexus() -> void:
	if choices.values().has("PENDING"):return
	stage = "nexus"
	save_game()
	_open_current()

func ending() -> String:
	if choices.values().has("PENDING"):return ""
	return "ending_a" if choices.values().count("RESTORE")>=2 else "ending_b"

func complete_nexus() -> bool:
	if stage!="nexus" or value("nexus_open")!=1 or ending().is_empty():return false
	put("nexus_confirmed",1)
	stage = "ending"
	save_game()
	_open_current()
	return true

func leave() -> void:
	active = false
	GameState.gaia_active = false
	GameState.input_locked = false
