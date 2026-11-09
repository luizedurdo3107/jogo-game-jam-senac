extends "res://tests/stations_test.gd"

func seed_choices(mask: int) -> void:
	StationJourney.reset()
	StationJourney.stage = "stations"
	for region in StationJourney.ORDER:
		var system: RefCounted = load("res://scripts/puzzles/%s_system.gd"%region).new()
		system.journey = StationJourney
		var commands: Array
		match region:
			"water":
				system.configure("water_route",1)
				commands = ["drain","module","install","valve_a","valve_a","valve_b","valve_b","authorize","pump","door"]
			"soil":
				system.configure("soil_capsules",10)
				system.configure("soil_temperature",1)
				commands = ["filter","install","humidity","authorize","irrigate","door"]
			_:
				commands = ["scan","module","install"]
		for command in commands:verify(system.interact(command).ok,"Preparação válida: "+region+"/"+command)
		if region=="air":
			system.configure("air_team",0)
			for command in ["coarse","carbon","turbine","filter","door"]:
				verify(system.interact(command).ok,"Preparação Atmos: "+command)
		StationJourney.station = region
		verify(StationJourney.decide("RESTORE" if mask&(1<<StationJourney.ORDER.find(region)) else "EXODUS"),"Decisão aceita: "+region)
		verify(not StationJourney.decide("RESTORE"),"Decisão não pode ser duplicada")
	StationJourney.stage = "nexus"

func persistence_checks() -> void:
	for mask in range(8):
		seed_choices(mask)
		var snapshot := StationJourney.snapshot()
		verify(StationJourney.validate(snapshot),"Snapshot válido: combinação "+str(mask))
		var restores := StationJourney.choices.values().count("RESTORE")
		verify(StationJourney.ending()==("ending_a" if restores>=2 else "ending_b"),"Maioria correta: "+str(mask))
		for key in StationJourney.LIMITS:
			var corrupt := snapshot.duplicate(true)
			corrupt.values[key] = StationJourney.LIMITS[key]+1
			verify(not StationJourney.validate(corrupt),"Limite rejeitado: "+key)
		for invalid in [-1,0.5,"1",null]:
			var corrupt := snapshot.duplicate(true)
			corrupt.values.nexus_scan = invalid
			verify(not StationJourney.validate(corrupt),"Tipo/valor inválido rejeitado")
		var broken := snapshot.duplicate(true)
		broken.values.nexus_open = 1
		verify(not StationJourney.validate(broken),"Painel não abre sem validação")
		var injected := snapshot.duplicate(true)
		injected.choices.extra = "RESTORE"
		verify(not StationJourney.validate(injected),"Escolha extra não altera a maioria")
		StationJourney.persistence_enabled = true
		verify(StationJourney.save_game(),"Save atômico: "+str(mask))
		StationJourney.reset()
		verify(StationJourney.load_game(),"Leitura do save: "+str(mask))
		verify(StationJourney.snapshot()==snapshot,"Round-trip preserva escolhas e técnica")
		var legacy := snapshot.duplicate(true)
		legacy.version = 1
		var file := FileAccess.open(StationJourney.save_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(legacy))
		file.close()
		verify(StationJourney.load_game() and StationJourney.snapshot().version==2,"Migração v1 para v2 sem fluxo 2D")
		StationJourney.persistence_enabled = false
	var corrupt_file := FileAccess.open(StationJourney.save_path,FileAccess.WRITE)
	corrupt_file.store_string("{invalid")
	corrupt_file.close()
	verify(not StationJourney.load_game(),"Save corrompido rejeitado")
	DirAccess.remove_absolute(StationJourney.save_path)

func nexus_route() -> void:
	seed_choices(7)
	await open_station("nexus")
	StationJourney.stage = "nexus"
	verify(game.player is CharacterBody3D and game.camera is Camera3D,"NEXUS é 2.5D real")
	verify(not game.interact_object("door"),"Painel final inicialmente trancado")
	verify(not game.interact_object("transmitter"),"Final bloqueado antes do puzzle")
	await move_to(4)
	await operate("voss")
	await mode(true)
	verify(not game.interact_object("locks"),"GAIA não libera travas físicas")
	await move_to(11)
	await climb_to(2.6)
	await move_to(11)
	await operate("scan")
	await mode(false)
	await move_to(11)
	await climb_to(0)
	await move_to(13.3)
	await climb_to(-2.7)
	await move_to(18)
	await operate("locks")
	await move_to(24.5)
	await climb_to(0)
	await move_to(24.5)
	await climb_to(2.6)
	await mode(true)
	await move_to(24)
	await operate("authorize")
	await move_to(24.5)
	await climb_to(0)
	await mode(false)
	await move_to(27)
	await operate("door")
	await frames(80)
	verify(game.environment.gate.collision_layer==0,"NEXUS abre passagem real")
	await move_to(32)
	await operate("transmitter")
	verify(game.hud.modal_open,"Resumo final acessível por interface")
	game.hud.close_modal()
	verify(StationJourney.complete_nexus(),"Confirmação final aceita")
	verify(SceneRouter.last_requested=="ending" and StationJourney.stage=="ending","Fluxo termina em epílogo 3D")
	verify(StationJourney.validate(StationJourney.snapshot()),"Final continua persistível")
	game.queue_free()
	await frames(5)

func ending_scenes() -> void:
	for mask in [0,7]:
		seed_choices(mask)
		for flag in ["nexus_voss","nexus_scan","nexus_locks","nexus_authorized","nexus_open"]:StationJourney.put(flag,1)
		StationJourney.complete_nexus()
		var ending_scene: Node3D = load("res://scenes/regions/epilogue.tscn").instantiate()
		add_child(ending_scene)
		await frames(10)
		verify(ending_scene.player is CharacterBody3D,"Final "+StationJourney.ending()+" mantém cenário 3D")
		verify(ending_scene.hud.get_child_count()>0,"Final apresenta narrativa e botão de retorno")
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
	StationJourney.save_path = "user://mobile_qa_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
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
	await nexus_route()
	await ending_scenes()
	audio_checks()
	for player in AudioDirector.physical_players+AudioDirector.ui_players+[AudioDirector.digital_player,AudioDirector.music_player]:
		player.stop()
		player.stream = null
	await frames(75)
	print("JORNADA MOBILE: %d verificações, %d falhas"%[assertions,failures])
	get_tree().quit(0 if failures==0 else 1)
