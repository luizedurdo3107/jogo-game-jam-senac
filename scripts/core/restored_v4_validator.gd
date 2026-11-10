extends RefCounted

const INTRO_FLAGS := ["recife_awake","recife_scan","recife_cell","recife_power","recife_authorized","recife_gate","recife_archive","recife_drone"]
const STORY_FLAGS := ["nova_contact","nova_module","nova_credential","nova_power","nova_open","nova_escaped","ruins_contact","ruins_water","ruins_gate","ruins_memory","ruins_drone"]
const ORDER := ["water","soil","air"]
const LIMITS := {"intro_seen":1,"nova_contact":1,"nova_module":1,"nova_credential":1,"nova_power":1,"nova_open":1,"nova_escaped":1,"ruins_contact":1,"ruins_water":1,"ruins_gate":1,"ruins_memory":1,"ruins_drone":1,"final_destination":2,"boss_mask":7,"boss_done":1,"recife_awake":1,"recife_scan":1,"recife_cell":1,"recife_power":1,"recife_authorized":1,"recife_gate":1,"recife_archive":1,"recife_drone":1,"nexus_voss":1,"nexus_scan":1,"nexus_locks":1,"nexus_authorized":1,"nexus_open":1,"nexus_confirmed":1,"water_route":2,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1,"water_memory":1,"soil_filter":2,"soil_mask":15,"soil_humidity":2,"soil_temperature":2,"soil_authorized":1,"soil_irrigation":1,"soil_open":1,"soil_memory":1,"air_scan":1,"air_team":1,"air_module":2,"air_sequence":3,"air_filter":2,"air_drone":1,"air_open":1,"air_memory":1}

func validate(data: Variant) -> bool:
	if not data is Dictionary or data.get("version",0)!=4 or data.get("station","") not in ORDER or data.get("stage","") not in ["cinematic","nova","ruins","intro","stations","nexus","boss","ending"]:return false
	if not data.get("values") is Dictionary or not data.get("choices") is Dictionary or not data.get("checkpoints") is Dictionary:return false
	for key in data.values:
		var number: Variant = data.values[key]
		if not LIMITS.has(key) or not (number is int or number is float) or not is_finite(float(number)) or float(number)!=floorf(float(number)) or number<0 or number>LIMITS[key]:return false
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
	for pair in [["nova_module","nova_contact"],["nova_credential","nova_contact"],["nova_power","nova_module"],["nova_open","nova_power"],["nova_open","nova_credential"],["nova_escaped","nova_open"],["ruins_water","ruins_contact"],["ruins_gate","ruins_water"]]:
		if int(data.values.get(pair[0],0))==1 and int(data.values.get(pair[1],0))!=1:return false
	var destination := int(data.values.get("final_destination",0))
	var boss_mask := int(data.values.get("boss_mask",0))
	if boss_mask not in [0,1,3,7] or (boss_mask>0 and destination!=1):return false
	if destination>0 and data.stage not in ["boss","ending"]:return false
	if data.stage in ["boss","ending"] and (destination==0 or int(data.values.get("nexus_open",0))!=1):return false
	if data.stage in ["boss","ending"] and int(data.values.get("nexus_confirmed",0))!=1:return false
	if data.stage=="boss" and destination!=1:return false
	if int(data.values.get("boss_done",0))==1 and (int(data.values.get("boss_mask",0))!=7 or destination!=1):return false
	if data.stage=="ending" and destination==1 and int(data.values.get("boss_done",0))!=1:return false
	return true
