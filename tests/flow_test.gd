extends "res://tests/journey_test.gd"

var captures := false

func close_dialogue() -> void:
	var world: Node = get_tree().current_scene
	if world.get("hud") and world.hud.get("modal_open")!=null:
		world.hud.touch.persistence_enabled = false
		world.hud.touch.set_manual_mode(2)
		if world.hud.modal_open:world.hud.close_modal()

func action(object_id: String, digital := false) -> void:
	if OS.has_feature("restoration_qa"):
		print("QA ACTION: ",StationJourney.region()," / ",object_id)
		if OS.has_feature("web"):JavaScriptBridge.eval("document.title = "+JSON.stringify("QA: "+StationJourney.region()+" / "+object_id),true)
	var world: Node3D = get_tree().current_scene
	close_dialogue()
	if GameState.gaia_active!=digital:verify(world.toggle_gaia(),"Troca de perspectiva / "+object_id)
	verify(world.interact_object(object_id),"Interação / "+object_id)
	await frames(2)
	close_dialogue()

func region_is(region_id: String) -> void:
	await frames(10)
	if OS.has_feature("restoration_qa"):print("QA REGION: ",region_id," / ",get_tree().current_scene.scene_file_path)
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES[region_id],"Transição real / "+region_id)
	close_dialogue()

func capture(name: String) -> void:
	if not captures:return
	await frames(2)
	var world: Node = get_tree().current_scene
	if world.get("hud") and world.hud.get("modal_open")!=null:world.hud._process(0.0)
	RenderingServer.force_draw()
	DirAccess.make_dir_recursive_absolute("res://outputs/qa/restoration")
	get_viewport().get_texture().get_image().save_png("res://outputs/qa/restoration/"+name+".png")

func run() -> void:
	captures = "--capture" in OS.get_cmdline_user_args()
	StationJourney.persistence_enabled = true
	StationJourney.save_path = "user://restored_flow_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	AudioDirector.persistence_enabled = false
	get_tree().current_scene = null
	for destination in ["EARTH","MARS"]:
		StationJourney.enter(false)
		await region_is("cinematic")
		var intro: Control = get_tree().current_scene
		verify(intro.shots.size()==6,"Introdução de seis planos")
		var duration := 0.0
		for entry in intro.shots:duration += entry.seconds
		verify(duration>=30 and duration<=60,"Duração-alvo da introdução")
		await capture("01_intro")
		intro.finish()
		await region_is("nova_eden")
		await capture("02_nova")
		await action("lyra")
		var nova: Node3D = get_tree().current_scene
		if captures:
			nova.interact_object("armory")
			await capture("02_nova_puzzle")
			close_dialogue()
		await arm_nova(nova)
		await frames(42)
		await capture("02_nova_arsenal")
		nova.player.position = Vector3(12.2,0.05,0)
		if captures:
			nova.combat.invulnerable = 5
			await frames(40)
		verify(nova.attack(),"Primeiro golpe contra soldado de Nova Éden")
		await capture("02_nova_combat")
		await defeat_nova(nova)
		await action("exit")
		await region_is("recife")
		await capture("03_recife")
		for object_id in ["nara","water_repair","archive","maintenance"]:await action(object_id)
		await action("exit")
		await region_is("laboratory")
		await capture("04_laboratory")
		if captures:
			get_tree().current_scene.hud.show_timeline()
			await frames(3)
			await capture("04_timeline")
			close_dialogue()
		for item in [["terminal",false],["scan",true],["cell",false],["socket",false],["authorize",true],["gate",false]]:await action(item[0],item[1])
		await action("exit")
		await region_is("water")
		for region_id in StationJourney.ORDER:
			var world: Node3D = get_tree().current_scene
			if region_id=="water":
				await action("route",true)
				verify(world.configure_system("water_route",1).ok,"Filtro comunitário")
				for item in [["drain",true],["module",false],["install",false],["valve_a",false],["valve_a",false],["valve_b",false],["valve_b",false],["authorize",true],["pump",false]]:await action(item[0],item[1])
			elif region_id=="soil":
				for item in [["filter",false],["install",false],["humidity",false]]:await action(item[0],item[1])
				world.toggle_gaia()
				verify(world.configure_system("soil_capsules",10).ok,"Seleção de cápsulas")
				verify(world.configure_system("soil_temperature",1).ok,"Clima da estufa")
				for item in [["authorize",true],["irrigate",false]]:await action(item[0],item[1])
			else:
				for item in [["scan",true],["module",false],["install",false]]:await action(item[0],item[1])
				verify(world.configure_system("air_team",0).ok,"Cooperação com equipe")
				for item in [["coarse",true],["carbon",true],["turbine",true],["filter",false]]:await action(item[0],item[1])
			await capture("05_"+region_id)
			world.finish("RESTORE" if region_id!="soil" else "EXODUS")
			close_dialogue()
			verify(world.interact_object("exit"),"Saída de "+region_id)
			await region_is({"water":"soil","soil":"air","air":"nexus"}[region_id])
		for item in [["voss",false],["scan",true]]:await action(item[0],item[1])
		var nexus: Node3D = get_tree().current_scene
		if nexus.perspectives.active:nexus.toggle_gaia()
		verify(nexus.interact_object("transmitter"),"Escolha definitiva acessível")
		await capture("06_choice")
		nexus.hud._confirm(destination)
		nexus.hud.modal_box.get_child(2).pressed.emit()
		if destination=="MARS":
			await region_is("boss")
			await capture("07_boss")
			verify(not get_tree().current_scene.interact_object("transmit"),"Exército impede embarque antes da luta")
			await defeat_departure(get_tree().current_scene)
			await capture("07_boss_victory")
			await action("breaker",true)
			await action("breaker",false)
			await action("redirect",true)
			await action("shutdown",false)
			await action("transmit")
		await region_is("ending")
		verify(StationJourney.value("boss_done")==(1 if destination=="MARS" else 0),"Confronto apenas antes da saída para Marte")
		verify(StationJourney.ending()==("ending_a" if destination=="EARTH" else "ending_b"),"Final corresponde à decisão definitiva")
		var ending_scene: Node3D = get_tree().current_scene
		for shot_index in range(ending_scene.shots.size()+1):
			if ending_scene.complete:break
			await frames(3)
			await capture("08_"+destination.to_lower()+"_"+str(ending_scene.shot))
			ending_scene._next()
		verify(ending_scene.return_button!=null,"Encerramento oferece retorno ao menu")
		StationJourney.enter(true)
		await region_is("ending")
		var resumed: Node3D = get_tree().current_scene
		verify(resumed.earth==(destination=="EARTH"),"Continuação preserva final")
		for shot_index in range(resumed.shots.size()+1):
			if resumed.complete:break
			resumed._next()
		resumed.return_button.pressed.emit()
		await frames(10)
		verify(get_tree().current_scene is Control and not StationJourney.active,"Final → menu")
	if is_instance_valid(get_tree().current_scene):get_tree().current_scene.queue_free()
	await frames(4)
	DirAccess.remove_absolute(StationJourney.save_path)
	print("FLUXO RESTAURADO / SETE REGIÕES / DOIS FINAIS: %d verificações, %d falhas"%[assertions,failures])
	if OS.has_feature("restoration_qa"):
		if OS.has_feature("web"):JavaScriptBridge.eval("document.title = "+JSON.stringify("QA FINAL: %d verificações / %d falhas"%[assertions,failures]),true)
		var result := SignalTheme.label("QA WEB / JORNADA RESTAURADA\n\n%d verificações · %d falhas\nSete regiões · três estações · dois finais\nTeste automatizado, não playtest humano."%[assertions,failures],26,SignalTheme.TEAL)
		result.position = Vector2(40,90)
		var canvas := CanvasLayer.new()
		canvas.add_child(result)
		add_child(canvas)
	elif failures>0:get_tree().quit(1)
	else:await AudioDirector.quit_game()
