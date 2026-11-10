extends "res://tests/test_fixture.gd"

func run() -> void:
	StationJourney.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	SceneRouter.test_mode = true
	for region_id in ["nova_eden","recife","laboratory"]:
		StationJourney.reset()
		game = load(StationJourney.SCENES[region_id]).instantiate()
		add_child(game)
		await frames(4)
		game.environment.open_gate()
		verify(game.environment.gate_animation.is_playing(),"Animação iniciada / "+region_id)
		SceneRouter.prepare_scene(game)
		verify(not game.environment.gate_animation.is_playing(),"Transição para a animação antes de liberar seus alvos / "+region_id)
		verify(game.process_mode==Node.PROCESS_MODE_DISABLED,"Cena de saída para de processar / "+region_id)
		remove_child(game)
		verify(not GameState.changed.is_connected(Callable(game,"_refresh")),"Cena removida não recebe alterações da próxima região / "+region_id)
		GameState.changed.emit()
		game.queue_free()
		await frames(3)
	print("CICLO DE VIDA / TRANSIÇÕES: %d verificações, %d falhas"%[assertions,failures])
	if failures>0:get_tree().quit(1)
	else:await AudioDirector.quit_game()
