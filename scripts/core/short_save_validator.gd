extends RefCounted

const INTRO_FLAGS := ["recife_awake","recife_scan","recife_cell","recife_power","recife_authorized","recife_gate","recife_archive","recife_drone"]
const ORDER := ["water"]
const LIMITS := {"recife_awake":1,"recife_scan":1,"recife_cell":1,"recife_power":1,"recife_authorized":1,"recife_gate":1,"recife_archive":1,"recife_drone":1,"water_route":2,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1,"water_memory":1,"signal_sent":1}


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
