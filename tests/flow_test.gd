extends "res://tests/journey_test.gd"

func run() -> void:
	StationJourney.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	get_tree().current_scene = null
	StationJourney.enter(false)
	await frames(12)
	verify(get_tree().current_scene is Node3D,"Nova jornada abre Recife 3D")
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.recife,"Entrada canônica no Recife")
	var world: Node3D = get_tree().current_scene
	for item in [["terminal",false],["scan",true],["cell",false],["socket",false],["authorize",true],["gate",false]]:
		if GameState.gaia_active!=item[1]:world.toggle_gaia()
		verify(world.interact_object(item[0]),"Prólogo aceita cooperação: "+item[0])
		if world.hud.modal_open:world.hud.close_modal()
	verify(world.interact_object("exit"),"Saída muda a cena de verdade")
	await frames(12)
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.water,"Recife → Capibaribe")
	seed_choices(7)
	StationJourney.station = "water"
	StationJourney.stage = "stations"
	StationJourney.advance()
	await frames(12)
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.soil,"Capibaribe → Banco Verde")
	StationJourney.advance()
	await frames(12)
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.air,"Banco Verde → Atmos")
	StationJourney.advance()
	await frames(12)
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.nexus,"Atmos → NEXUS 3D")
	world = get_tree().current_scene
	if world.hud.modal_open:world.hud.close_modal()
	for item in [["voss",false],["scan",true],["locks",false],["authorize",true],["door",false]]:
		if GameState.gaia_active!=item[1]:world.toggle_gaia()
		verify(world.interact_object(item[0]),"NEXUS aceita cooperação: "+item[0])
		if world.hud.modal_open:world.hud.close_modal()
	verify(StationJourney.complete_nexus(),"Confirmação muda a cena de verdade")
	await frames(12)
	verify(get_tree().current_scene.scene_file_path==StationJourney.SCENES.ending,"NEXUS → epílogo 3D")
	SceneRouter.menu()
	await frames(12)
	verify(get_tree().current_scene is Control and not StationJourney.active,"Retorno ao único menu")
	get_tree().current_scene.queue_free()
	await frames(5)
	print("FLUXO ENTRE CENAS: %d verificações, %d falhas"%[assertions,failures])
	await AudioDirector.quit_game()
