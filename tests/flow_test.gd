extends "res://tests/journey_test.gd"

func run() -> void:
	StationJourney.persistence_enabled = true
	StationJourney.save_path = "user://short_flow_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	AudioDirector.persistence_enabled = false
	get_tree().current_scene = null
	for choice in ["RESTORE","EXODUS"]:
		StationJourney.enter(false)
		await frames(12)
		verify(get_tree().current_scene is Node3D,"Nova jornada abre Recife 3D")
		verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.recife,"Primeira das duas fases é Recife")
		var world: Node3D = get_tree().current_scene
		for item in [["terminal",false],["scan",true],["cell",false],["socket",false],["authorize",true],["gate",false]]:
			if GameState.gaia_active!=item[1]:world.toggle_gaia()
			verify(world.interact_object(item[0]),"Prólogo aceita cooperação: "+item[0])
			if world.hud.modal_open:world.hud.close_modal()
		verify(world.interact_object("exit"),"Saída muda a cena de verdade")
		await frames(12)
		verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.water,"Recife → Capibaribe")
		world = get_tree().current_scene
		if world.hud.modal_open:world.hud.close_modal()
		world.toggle_gaia()
		world.interact_object("route")
		verify(world.configure_system("water_route",1).ok,"Rota segura configurada pela interface")
		world.hud.close_modal()
		for item in [["drain",true],["module",false],["install",false],["valve_a",false],["valve_a",false],["valve_b",false],["valve_b",false],["authorize",true],["pump",false],["door",false]]:
			if GameState.gaia_active!=item[1]:world.toggle_gaia()
			verify(world.interact_object(item[0]),"Puzzle final aceita cooperação: "+item[0])
			if world.hud.modal_open:world.hud.close_modal()
		verify(not world.interact_object("exit"),"Transmissor exige destino do núcleo")
		world.interact_object("decision")
		world.hud.modal_box.get_child(2 if choice=="RESTORE" else 3).pressed.emit()
		verify(StationJourney.choices.water==choice,"Escolha real registrada: "+choice)
		world.hud.close_modal()
		world.interact_object("exit")
		verify(world.hud.modal_open,"Transmissor permite conferir o encerramento")
		world.hud.modal_box.get_child(3).pressed.emit()
		verify(StationJourney.stage=="stations" and not world.hud.modal_open,"Cancelar não avança nem apaga escolha")
		world.interact_object("exit")
		world.hud.modal_box.get_child(2).pressed.emit()
		await frames(12)
		verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.ending,"Capibaribe → final, sem fase extra")
		verify(StationJourney.ending()==("ending_a" if choice=="RESTORE" else "ending_b"),"Desfecho corresponde ao destino da água")
		verify(StationJourney.value("signal_sent")==1,"Sinal final gravado")
		StationJourney.enter(true)
		await frames(12)
		verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.ending,"Continuar após conclusão retorna ao epílogo")
		get_tree().current_scene.return_button.pressed.emit()
		await frames(12)
		verify(get_tree().current_scene is Control and not StationJourney.active,"Botão do final retorna ao único menu")
	get_tree().current_scene.queue_free()
	await frames(5)
	DirAccess.remove_absolute(StationJourney.save_path)
	print("FLUXO CURTO / CENAS REAIS: %d verificações, %d falhas"%[assertions,failures])
	if failures>0:get_tree().quit(1)
	else:await AudioDirector.quit_game()
