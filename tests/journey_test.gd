extends "res://tests/stations_test.gd"

func seed_water(choice := "RESTORE") -> void:
	StationJourney.reset()
	StationJourney.stage = "stations"
	var system := preload("res://scripts/puzzles/water_system.gd").new()
	system.journey = StationJourney
	system.configure("water_route",1)
	for command in ["drain","module","install","valve_a","valve_a","valve_b","valve_b","authorize","pump","door"]:
		verify(system.interact(command).ok,"Preparação válida: "+command)
	verify(StationJourney.decide(choice),"Decisão aceita: "+choice)

func legacy_snapshot(version: int, destination: String, choice: String) -> Dictionary:
	var data := {"version":version,"station":"water","stage":"stations","values":{"water_route":1,"water_drained":1,"water_module":2,"water_a":2,"water_b":2,"water_authorized":1,"water_pump":1,"water_open":1},"choices":{"water":choice,"soil":"PENDING","air":"PENDING"},"checkpoints":{"water":[31.0,0.05]}}
	if destination=="intro":
		data.stage = "intro"
		data.choices.water = "PENDING"
		data.values = {"recife_awake":1}
		data.checkpoints = {"recife":[8.0,0.05]}
	elif destination in ["soil","air","nexus","ending"]:
		data.station = "soil" if destination=="soil" else "air"
		data.choices.soil = "RESTORE"
		data.values.merge({"soil_filter":2,"soil_mask":10,"soil_humidity":1,"soil_temperature":1,"soil_authorized":1,"soil_irrigation":1,"soil_open":1})
		if destination in ["air","nexus","ending"]:
			data.choices.air = "EXODUS"
			data.values.merge({"air_scan":1,"air_module":2,"air_team":1,"air_sequence":3,"air_filter":1,"air_open":1})
			data.checkpoints.air = [22.0,7.8]
		if destination in ["nexus","ending"]:data.stage = destination
		if destination=="ending":
			data.values.merge({"nexus_voss":1,"nexus_scan":1,"nexus_locks":1,"nexus_authorized":1,"nexus_open":1,"nexus_confirmed":1})
	return data

func persistence_checks() -> void:
	StationJourney.persistence_enabled = false
	for choice in ["RESTORE","EXODUS"]:
		seed_water(choice)
		var snapshot := StationJourney.snapshot()
		verify(StationJourney.validate(snapshot),"Snapshot v3 válido")
		for key in StationJourney.LIMITS:
			var corrupt := snapshot.duplicate(true)
			corrupt.values[key] = StationJourney.LIMITS[key]+1
			verify(not StationJourney.validate(corrupt),"Limite rejeitado: "+key)
		for invalid in [-1,0.5,"1",null]:
			var corrupt := snapshot.duplicate(true)
			corrupt.values.water_route = invalid
			verify(not StationJourney.validate(corrupt),"Valor/campo inválido rejeitado")
		for removed in ["soil","air","nexus"]:
			var corrupt := snapshot.duplicate(true)
			corrupt.station = removed
			verify(not StationJourney.validate(corrupt),"Fase removida não pode voltar pelo save")
		var injected := snapshot.duplicate(true)
		injected.choices.extra = "RESTORE"
		verify(not StationJourney.validate(injected),"Decisão extra rejeitada")
		verify(not StationJourney.decide("EXODUS"),"Destino confirmado não é reescrito")
		StationJourney.persistence_enabled = true
		verify(StationJourney.save_game(),"Save atômico v3")
		StationJourney.reset()
		verify(StationJourney.load_game() and StationJourney.snapshot()==snapshot,"Round-trip da decisão")
		verify(StationJourney.complete_signal(),"Transmissão chega ao final sem outras fases")
		var ending_snapshot := StationJourney.snapshot()
		verify(StationJourney.validate(ending_snapshot),"Final persistível")
		StationJourney.reset()
		verify(StationJourney.load_game() and StationJourney.snapshot()==ending_snapshot,"Continue preserva o final")
		verify(not StationJourney.complete_signal(),"Final não pode ser transmitido em duplicidade")
		StationJourney.persistence_enabled = false
	for version in [1,2]:
		for destination in ["intro","water","soil","air","nexus","ending"]:
			if version==1 and destination in ["intro","ending"]:continue
			for choice in ["RESTORE","EXODUS"]:
				var previous := legacy_snapshot(version,destination,choice)
				var bytes_before := JSON.stringify(previous)
				var converted := StationJourney.migrate(previous)
				verify(not converted.is_empty() and StationJourney.validate(converted),"Migração v%d / %s / %s"%[version,destination,choice])
				verify(JSON.stringify(previous)==bytes_before,"Migração não modifica o save original")
				verify(converted.stage==("intro" if destination=="intro" else "stations"),"Migração não exige fase removida nem transmite sem confirmação")
				verify(converted.choices.water==("PENDING" if destination=="intro" else choice),"Migração mantém o destino da água")
				verify(not converted.checkpoints.has("air") and not converted.values.has("air_open"),"Progresso removido não contamina a campanha curta")
	var invalid_legacy := legacy_snapshot(2,"water","RESTORE")
	invalid_legacy.values.water_pump = 0
	verify(StationJourney.migrate(invalid_legacy).is_empty(),"Save antigo inconsistente não é importado")
	var source_path := StationJourney.save_path+".legacy"
	var source := FileAccess.open(source_path,FileAccess.WRITE)
	var original := JSON.stringify(legacy_snapshot(2,"nexus","EXODUS"))
	source.store_string(original)
	source.close()
	var destination_path := StationJourney.save_path
	StationJourney.save_path = source_path
	verify(StationJourney.load_game(),"Leitura do arquivo antigo migra para duas fases")
	verify(FileAccess.get_file_as_string(source_path)==original,"Leitura não sobrescreve o arquivo antigo")
	StationJourney.save_path = destination_path
	StationJourney.persistence_enabled = true
	verify(StationJourney.save_game(),"Estado importado pode ser salvo no novo arquivo")
	verify(FileAccess.get_file_as_string(source_path)==original,"Novo save mantém o arquivo antigo intacto")
	var safe_path := StationJourney.save_path
	StationJourney.save_path = "user://missing_"+Crypto.new().generate_random_bytes(8).hex_encode()+"/save.json"
	verify(not StationJourney.complete_signal() and StationJourney.stage=="stations" and StationJourney.value("signal_sent")==0,"Falha de gravação não perde o final nem marca transmissão falsa")
	StationJourney.save_path = safe_path
	StationJourney.persistence_enabled = false
	var corrupt_file := FileAccess.open(StationJourney.save_path,FileAccess.WRITE)
	corrupt_file.store_string("{invalid")
	corrupt_file.close()
	verify(not StationJourney.load_game(),"Save corrompido rejeitado")
	DirAccess.remove_absolute(source_path)
	DirAccess.remove_absolute(StationJourney.save_path)
	StationJourney.reset()
	verify(not StationJourney.complete_signal(),"Não há final sem puzzle e escolha")

func ending_scenes() -> void:
	for choice in ["RESTORE","EXODUS"]:
		seed_water(choice)
		StationJourney.complete_signal()
		var ending_scene: Node3D = load("res://scenes/regions/epilogue.tscn").instantiate()
		add_child(ending_scene)
		await frames(10)
		verify(ending_scene.player is CharacterBody3D,"Final "+StationJourney.ending()+" mantém cenário 3D")
		verify(ending_scene.hud.get_child_count()>0,"Final tem narrativa e retorno ao menu")
		ending_scene.queue_free()
		await frames(5)

func audio_checks() -> void:
	for bus in AudioDirector.BUSES:
		verify(AudioServer.get_bus_index(bus)>=0,"Bus de áudio: "+bus)
	for sound_id in AudioDirector.catalog:
		var entry: Dictionary = AudioDirector.catalog[sound_id]
		for index in range(entry.paths.size()):
			verify(AudioDirector.stream_for(sound_id,index)!=null,"Recurso sonoro disponível: "+str(entry.paths[index]))
	AudioDirector.set_gaia(true,false)
	verify(AudioDirector.gaia,"GAIA altera mixagem")
	AudioDirector.set_gaia(false,false)


func run() -> void:
	StationJourney.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	SceneRouter.test_mode = true
	StationJourney.save_path = "user://short_qa_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	await open_demo()
	verify(game.player is CharacterBody3D,"Protagonista é CharacterBody3D")
	verify(game.player.sprite is AnimatedSprite3D,"Sprites originais em AnimatedSprite3D")
	verify(game.player.sprite.sprite_frames.get_frame_count("idle")==8,"Oito quadros originais preservados")
	verify(game.camera is Camera3D,"Câmera 3D real")
	verify(game.environment.get_child_count()>20,"Geometria e iluminação tridimensionais")
	verify(game.player.is_on_floor(),"Colisão inicial com piso 3D")
	verify(not GameState.persistence_enabled,"Sessão não grava o antigo save 2D")
	verify(not game.toggle_gaia(),"GAIA não ativa antes da descoberta")
	verify(not game.interact_object("gate"),"Comporta bloqueada sem puzzle")
	verify(not game.interact_object("scan"),"Circuito inacessível no modo físico")
	var initial_height: float = game.player.position.y
	Input.action_press("jump")
	await frames(12)
	Input.action_release("jump")
	verify(game.player.position.y>initial_height+0.7,"Salto real com gravidade")
	await frames(70)
	verify(game.player.is_on_floor(),"Pouso após salto")
	await move_to(8)
	await use_near("terminal")
	verify(GameState.gaia_unlocked,"Terminal desperta GAIA")
	verify(game.toggle_gaia(),"Alternância para GAIA disponível")
	await frames(3)
	verify(game.environment.circuit.visible and game.markers.scan.visible,"Circuitos ocultos revelados")
	await move_to(11)
	await climb_to(2.6)
	await move_to(14.8)
	await use_near("scan")
	verify(GameState.has_flag("recife_scan"),"Diagnóstico com GAIA")
	await move_to(18.4)
	verify(not game.interact_object("maintenance"),"Mecanismo físico recusa GAIA")
	game.toggle_gaia()
	await use_near("maintenance")
	verify(GameState.has_flag("recife_drone"),"Drone redirecionado sem combate")
	game.toggle_gaia()
	await move_to(20)
	await use_near("archive")
	verify(GameState.has_flag("recife_archive"),"Área opcional investigada")
	game.toggle_gaia()
	await move_to(21)
	await climb_to(0)
	await move_to(13.3)
	await climb_to(-2.7)
	await move_to(17)
	await use_near("cell")
	verify(GameState.inventory.has("recife_cell"),"Célula recolhida no subsolo")
	await move_to(24.5)
	await climb_to(0)
	await move_to(21.7)
	await use_near("socket")
	verify(GameState.has_flag("recife_power") and not GameState.inventory.has("recife_cell"),"Célula transfere energia uma única vez")
	verify(not game.interact_object("socket"),"Repetição não duplica recurso")
	await move_to(25.7)
	verify(not game.interact_object("authorize"),"Autorização requer perspectiva digital")
	game.toggle_gaia()
	await use_near("authorize")
	verify(GameState.has_flag("recife_authorized"),"Autorização digital com energia")
	game.toggle_gaia()
	await move_to(27)
	await use_near("gate")
	verify(game.environment.gate.collision_layer==0,"Comporta remove bloqueio físico")
	StationJourney.persistence_enabled = true
	verify(StationJourney.save_game(),"Progresso do Recife gravado")
	var intro_snapshot := StationJourney.snapshot()
	StationJourney.reset()
	var loaded_intro := StationJourney.load_game()
	var expected_point := Vector3(intro_snapshot.checkpoints.recife[0],intro_snapshot.checkpoints.recife[1],0)
	verify(loaded_intro and StationJourney.stage=="intro" and StationJourney.values==intro_snapshot.values and StationJourney.checkpoint().is_equal_approx(expected_point),"Prólogo retorna do save sem perder o circuito")
	StationJourney.persistence_enabled = false
	await frames(80)
	verify(game.environment.gate_visual.position.y>3.5,"AnimationPlayer abre comporta")

	await move_to(32)
	await use_near("exit")
	verify(StationJourney.stage=="stations" and SceneRouter.last_requested=="water","Recife segue ao Capibaribe, não a outra versão")
	verify(StationJourney.validate(StationJourney.snapshot()),"Progresso do prólogo válido")
	game.queue_free()
	await frames(5)
	persistence_checks()
	await ending_scenes()
	audio_checks()
	for player in AudioDirector.physical_players+AudioDirector.ui_players+[AudioDirector.digital_player,AudioDirector.music_player]:
		player.stop()
		player.stream = null
	await frames(75)
	print("JORNADA CURTA: %d verificações, %d falhas"%[assertions,failures])
	get_tree().quit(0 if failures==0 else 1)
