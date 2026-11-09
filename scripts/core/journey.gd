extends Node

signal changed

const SAVE_PATH := "user://last_signal_short_v3.json"
const LEGACY_PATHS := ["user://last_signal_mobile_v2.json","user://stations_25d_v1.json"]
const SCENES := {"recife":"res://scenes/regions/recife.tscn","water":"res://scenes/regions/water.tscn","ending":"res://scenes/regions/epilogue.tscn"}
const INTRO_FLAGS := ["recife_awake","recife_scan","recife_cell","recife_power","recife_authorized","recife_gate","recife_archive","recife_drone"]
const ORDER := ["water"]
const LIMITS := {"recife_awake":1,"recife_scan":1,"recife_cell":1,"recife_power":1,"recife_authorized":1,"recife_gate":1,"recife_archive":1,"recife_drone":1,"water_route":2,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1,"water_memory":1,"signal_sent":1}

var station := "water"
var stage := "intro"
var values: Dictionary = {}
var choices := {"water":"PENDING"}
var checkpoints: Dictionary = {}
var persistence_enabled := true
var save_path := SAVE_PATH
var active := false

func reset() -> void:
	station = "water"
	stage = "intro"
	values.clear()
	choices = {"water":"PENDING"}
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
	return {"version":3,"station":station,"stage":stage,"values":values.duplicate(),"choices":choices.duplicate(),"checkpoints":checkpoints.duplicate(true)}

func validate(data: Variant) -> bool:
	if not data is Dictionary or data.get("version",0)!=3 or data.get("station","")!="water" or data.get("stage","") not in ["intro","stations","ending"]:
		return false
	if not data.get("values") is Dictionary or not data.get("choices") is Dictionary or not data.get("checkpoints") is Dictionary:
		return false
	if data.choices.size()!=1 or data.choices.get("water","") not in ["PENDING","RESTORE","EXODUS"]:
		return false
	for key in data.values:
		var number: Variant = data.values[key]
		if not LIMITS.has(key) or not (number is int or number is float) or not is_finite(float(number)) or float(number)!=floorf(float(number)) or number<0 or number>LIMITS[key]:
			return false
	for region_id in data.checkpoints:
		var point: Variant = data.checkpoints[region_id]
		if region_id not in ["recife","water"] or not point is Array or point.size()!=2:
			return false
		for coordinate in point:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):return false
		if point[0]<0 or point[0]>36 or point[1]<-3 or point[1]>8:return false
	var technical: Dictionary = data.values
	for pair in [["recife_scan","recife_awake"],["recife_cell","recife_scan"],["recife_power","recife_cell"],["recife_authorized","recife_power"],["recife_gate","recife_authorized"],["water_pump","water_authorized"],["water_open","water_pump"]]:
		if int(technical.get(pair[0],0))==1 and int(technical.get(pair[1],0))!=1:return false
	if int(technical.get("water_module",0))>0 and int(technical.get("water_drained",0))!=1:return false
	if int(technical.get("water_authorized",0))==1 and (int(technical.get("water_module",0))!=2 or int(technical.get("water_route",0))!=1 or int(technical.get("water_a",0))*20+int(technical.get("water_b",0))*10!=60):return false
	if data.choices.water!="PENDING" and int(technical.get("water_open",0))!=1:return false
	if data.stage=="intro" and data.choices.water!="PENDING":return false
	if data.stage=="ending":
		if data.choices.water=="PENDING" or int(technical.get("signal_sent",0))!=1:return false
	elif int(technical.get("signal_sent",0))!=0:return false
	return true

func migrate(data: Variant) -> Dictionary:
	var legacy := preload("res://scripts/core/legacy_journey_save.gd").new()
	var converted: Dictionary = legacy.convert(data,LIMITS.keys())
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
	if data.is_empty():return false
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
	if not persistence_enabled:return true
	var data := snapshot()
	if not validate(data):return false
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify(data,"",true,true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error!=OK:return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))==OK

func region() -> String:
	return "recife" if stage=="intro" else "water"

func enter(continuing := true) -> void:
	if not continuing or not load_game():reset()
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
	if stage!="intro" or value("recife_gate")!=1:return
	stage = "stations"
	save_game()
	_open_current()

func ending() -> String:
	return str({"RESTORE":"ending_a","EXODUS":"ending_b"}.get(choices.water,""))

func complete_signal() -> bool:
	if stage!="stations" or value("water_open")!=1 or ending().is_empty():return false
	put("signal_sent",1)
	stage = "ending"
	if not save_game():
		stage = "stations"
		values.erase("signal_sent")
		changed.emit()
		return false
	_open_current()
	return true

func decide(choice: String) -> bool:
	if stage!="stations" or choice not in ["RESTORE","EXODUS"] or value("water_open")!=1 or choices.water!="PENDING":return false
	choices.water = choice
	if not save_game():
		choices.water = "PENDING"
		changed.emit()
		return false
	GameState.station_choices = choices.duplicate()
	return true

func leave() -> void:
	active = false
	GameState.gaia_active = false
	GameState.input_locked = false
