extends "res://tests/stations_test.gd"

func seed_station(region_id: String, choice := "RESTORE") -> void:
	StationJourney.stage = "stations"
	StationJourney.station = region_id
	var system: RefCounted = load("res://scripts/puzzles/%s_system.gd"%region_id).new()
	system.journey = StationJourney
	if region_id=="water":
		system.configure("water_route",1)
		for command in ["drain","module","install","valve_a","valve_a","valve_b","valve_b","authorize","pump"]:verify(system.interact(command).ok,"Água / "+command)
	elif region_id=="soil":
		for command in ["filter","install","humidity"]:system.interact(command)
		system.configure("soil_capsules",10)
		system.configure("soil_temperature",1)
		for command in ["authorize","irrigate"]:verify(system.interact(command).ok,"Vida / "+command)
	else:
		for command in ["scan","module","install"]:system.interact(command)
		system.configure("air_team",0)
		for command in ["coarse","carbon","turbine","filter"]:verify(system.interact(command).ok,"Ar / "+command)
	verify(StationJourney.decide(choice),"Decisão de "+region_id)

func seed_nexus() -> void:
	StationJourney.stage = "nexus"
	var system := preload("res://scripts/puzzles/nexus_system.gd").new()
	system.journey = StationJourney
	for command in system.STEPS:verify(system.interact(command).ok,"NEXUS / "+command)

func run() -> void:
	SceneRouter.test_mode = true
	StationJourney.persistence_enabled = true
	StationJourney.save_path = "user://restoration_test_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	StationJourney.reset()
	verify(StationJourney.validate(StationJourney.snapshot()),"Nova campanha v6 válida")
	verify(StationJourney.save_game(),"Escrita atômica inicial")
	verify(not StationJourney.advance_story(),"Não pula regiões sem objetivos")
	StationJourney.finish_intro()
	verify(StationJourney.region()=="nova_eden","Introdução leva à Nova Éden")
	for key in ["nova_contact","nova_open","nova_escaped"]:StationJourney.put(key,1)
	StationJourney.put("nova_security",7)
	verify(StationJourney.advance_story() and StationJourney.region()=="recife","Nova Éden → ruínas")
	for key in ["ruins_contact","ruins_water","ruins_gate"]:StationJourney.put(key,1)
	verify(StationJourney.advance_story() and StationJourney.region()=="laboratory","Ruínas → laboratório")
	for key in StationJourney.INTRO_FLAGS:StationJourney.put(key,1)
	verify(StationJourney.advance_story() and StationJourney.region()=="water","Laboratório → Capibaribe")
	for region_id in StationJourney.ORDER:
		seed_station(region_id,"EXODUS" if region_id=="soil" else "RESTORE")
		verify(StationJourney.validate(StationJourney.snapshot()),"Estado técnico válido / "+region_id)
		StationJourney.store_checkpoint(Vector3(3,0.05,0))
		verify(StationJourney.save_game() and StationJourney.load_game(),"Estado e checkpoint persistem / "+region_id)
		verify(not StationJourney.decide("RESTORE"),"Decisão não é reescrita")
		StationJourney.advance()
	verify(StationJourney.stage=="nexus","Três estações levam ao porto")
	seed_nexus()
	var full := StationJourney.snapshot()
	for key in StationJourney.LIMITS:
		var corrupt := full.duplicate(true)
		corrupt.values[key] = StationJourney.LIMITS[key]+1
		verify(not StationJourney.validate(corrupt),"Limite rejeitado / "+key)
	for point in [[-1,0],[3,9],[3,"0"],[INF,0],[3]]:
		var corrupt := full.duplicate(true)
		corrupt.checkpoints.nexus = point
		verify(not StationJourney.validate(corrupt),"Checkpoint inválido rejeitado")
	for version in [1,2]:
		var legacy := full.duplicate(true)
		legacy.version = version
		legacy.checkpoints.clear()
		for key in full.values:
			if not preload("res://scripts/core/legacy_journey_save.gd").LIMITS.has(key):legacy.values.erase(key)
		var converted := StationJourney.migrate(legacy)
		verify(not converted.is_empty(),"Compatibilidade v%d"%version)
		verify(converted.get("choices",{})==full.choices,"Três escolhas antigas preservadas")
		var forged := legacy.duplicate(true)
		forged.values.water_open = 0
		verify(StationJourney.migrate(forged).is_empty(),"Legado inválido não é aceito")
	var short := {"version":3,"station":"water","stage":"ending","values":{},"choices":{"water":"RESTORE"},"checkpoints":{}}
	for key in full.values:
		if key.begins_with("water_"):short.values[key] = full.values[key]
	short.values.signal_sent = 1
	var migrated := StationJourney.migrate(short)
	verify(not migrated.is_empty() and migrated.stage=="stations","Final curto volta às estações restantes")
	verify(migrated.choices.soil=="PENDING" and migrated.choices.air=="PENDING","Migração não inventa decisões")
	var legacy_base := full.duplicate(true)
	legacy_base.values.erase("nova_security")
	for key in ["nova_module","nova_credential","nova_power"]:legacy_base.values[key] = 1
	var old_earth := legacy_base.duplicate(true)
	old_earth.version = 4
	old_earth.stage = "boss"
	old_earth.values.merge({"final_destination":1,"nexus_confirmed":1,"boss_mask":3})
	var revised := StationJourney.migrate(old_earth)
	verify(not revised.is_empty() and revised.stage=="ending","Save v4 da Terra deixa de exigir confronto")
	verify(int(revised.values.get("boss_mask",0))==0 and revised.choices==full.choices,"Migração remove só o bloqueio antigo, não recursos")
	old_earth.stage = "ending"
	old_earth.values.merge({"boss_mask":7,"boss_done":1},true)
	verify(not StationJourney.migrate(old_earth).is_empty(),"Final A v4 concluído continua válido")
	var old_mars := legacy_base.duplicate(true)
	old_mars.version = 4
	old_mars.stage = "ending"
	old_mars.values.merge({"final_destination":2,"nexus_confirmed":1})
	var departed := StationJourney.migrate(old_mars)
	verify(not departed.is_empty() and departed.values.get("legacy_departure",0)==1,"Final B v4 já concluído não é apagado nem inventa confronto")
	var old_v5 := legacy_base.duplicate(true)
	old_v5.version = 5
	var upgraded := StationJourney.migrate(old_v5)
	verify(not upgraded.is_empty() and upgraded.version==6 and upgraded.values.get("nova_legacy_passage",0)==1,"Save v5 preserva a passagem inicial sem inventar combate")
	verify(StationJourney.choose_destination("EARTH") and StationJourney.stage=="ending","Ficar na Terra não inicia confronto")
	verify(StationJourney.value("boss_mask")==0 and not StationJourney.complete_boss(),"Terra não depende de circuitos de fuga")
	verify(StationJourney.load_game() and StationJourney.ending()=="ending_a","Final A persiste sem confronto")
	StationJourney.stage = "nexus"
	StationJourney.values = full.values.duplicate()
	verify(StationJourney.choose_destination("MARS") and StationJourney.stage=="boss","Partir para Marte inicia o bloqueio de saída")
	verify(not StationJourney.complete_boss(),"Não embarca antes de superar a contenção")
	var premature := StationJourney.snapshot()
	premature.stage = "ending"
	verify(not StationJourney.validate(premature),"Save novo não pula confronto de saída para Marte")
	for mask in [1,3,7]:
		StationJourney.put("boss_mask",mask)
		verify(StationJourney.save_game(),"Checkpoint do confronto de embarque")
	verify(not StationJourney.complete_boss(),"Circuitos desligados não substituem vitória contra o exército")
	StationJourney.put("departure_security",7)
	verify(StationJourney.complete_boss() and StationJourney.stage=="ending","Confronto concluído libera final B")
	verify(StationJourney.load_game() and StationJourney.ending()=="ending_b","Final B persiste depois do confronto")
	var save_text := FileAccess.get_file_as_string(StationJourney.save_path)
	var file := FileAccess.open(StationJourney.save_path,FileAccess.WRITE)
	file.store_string("{ quebrado")
	file.close()
	verify(not StationJourney.load_game(),"JSON corrompido não altera a partida")
	file = FileAccess.open(StationJourney.save_path,FileAccess.WRITE)
	file.store_string(save_text)
	file.close()
	StationJourney.enter(false)
	verify(StationJourney.stage=="cinematic" and StationJourney.choices.values().count("PENDING")==3,"Reinício completo")
	DirAccess.remove_absolute(StationJourney.save_path)
	print("JORNADA RESTAURADA: %d verificações, %d falhas"%[assertions,failures])
	get_tree().quit(0 if failures==0 else 1)
