extends RefCounted

const ORDER := ["water","soil","air"]
const LIMITS := {"recife_awake":1,"recife_scan":1,"recife_cell":1,"recife_power":1,"recife_authorized":1,"recife_gate":1,"recife_archive":1,"recife_drone":1,"nexus_voss":1,"nexus_scan":1,"nexus_locks":1,"nexus_authorized":1,"nexus_open":1,"nexus_confirmed":1,"water_route":2,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1,"water_memory":1,"soil_filter":2,"soil_mask":15,"soil_humidity":2,"soil_temperature":2,"soil_authorized":1,"soil_irrigation":1,"soil_open":1,"soil_memory":1,"air_scan":1,"air_team":1,"air_module":2,"air_sequence":3,"air_filter":2,"air_drone":1,"air_open":1,"air_memory":1}

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


func convert(data: Variant, allowed_keys: Array) -> Dictionary:
	if not validate(data):return {}
	var converted := {"version":3,"station":"water","stage":"intro" if data.stage=="intro" else "stations","values":{},"choices":{"water":data.choices.water},"checkpoints":{}}
	for key in data.values:
		if key in allowed_keys:converted.values[key] = int(data.values[key])
	for region in ["recife","water"]:
		if data.checkpoints.has(region):converted.checkpoints[region] = data.checkpoints[region].duplicate()
	return converted
