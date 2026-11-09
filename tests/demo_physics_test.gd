extends "res://tests/test_fixture.gd"

func run() -> void:
	suite_name = "FÍSICA 3D / ELEVADOR / VIGILÂNCIA"
	await open_demo()
	GameState.flags.recife_drone = true
	verify(not game.operate_lift(),"Elevador recusa operação sem energia")
	GameState.flags.recife_power = true
	game.player.position = Vector3(23.2,0.1,0)
	await frames(16)
	verify(game.player.is_on_floor(),"Cabine suporta o passageiro")
	for stop_height in [2.6,-2.7,0.0]:
		verify(game.operate_lift(),"Elevador aceita próxima parada")
		await frames(225)
		verify(absf(game.lift.position.y+0.12-stop_height)<0.05,"Cabine chega a "+str(stop_height))
		verify(absf(game.player.position.y-stop_height)<0.18,"Passageiro transportado até "+str(stop_height))
	game.player.position = Vector3(10,0.1,0)
	await frames(16)
	game.player.position.z = 0.9
	await frames(2)
	verify(is_zero_approx(game.player.position.z),"Movimento permanece no plano lateral")
	game.hud.show_pause()
	var paused_position: Vector3 = game.player.position
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(15)
	Input.action_release("move_right")
	Input.action_release("jump")
	verify(game.player.position.is_equal_approx(paused_position),"Pausa bloqueia física do protagonista")
	game.hud.close_modal()
	game.environment.reduced = true
	game.toggle_quality()
	verify(is_equal_approx(game.get_viewport().scaling_3d_scale,1.0),"Perfil normal usa resolução integral no desktop")
	game.toggle_quality()
	verify(is_equal_approx(game.get_viewport().scaling_3d_scale,0.75),"Perfil reduzido diminui resolução 3D")
	GameState.flags.recife_drone = false
	game.grace = 0
	game.player.position = Vector3(game.drone.position.x,-2.68,0)
	await frames(130)
	verify(game.suspicion<0.05,"Túnel evita detecção da patrulha da rua")
	var redirected := false
	for tick in range(180):
		game.player.position = Vector3(game.drone.position.x,0.05,0)
		await frames(1)
		if game.grace>0:
			redirected = true
			break
	verify(redirected,"Drone solicita retorno ao abrigo sem combate")
	verify(game.player.position.distance_to(game.checkpoint)<0.2,"Retorno usa ponto seguro")
	verify(GameState.has_flag("recife_power"),"Patrulha não apaga progresso")
	for sound_id in ["click","gaia","gate","restore","exodus"]:
		game.play_sound(sound_id)
		verify(game.audio.stream is AudioStreamWAV,"Áudio local carregado: "+sound_id)
		verify(game.audio.stream.data.size()>0,"Amostras PCM disponíveis: "+sound_id)
	game.set_muted(true)
	verify(game.audio.volume_db<=-80,"Controle de áudio silencia reprodução")
	game.audio.stop()
	game.audio.stream = null
	game.queue_free()
	await frames(3)
	OS.delay_msec(100)
	print("%s: %d verificações, %d falhas"%[suite_name,assertions,failures])
	get_tree().quit(0 if failures==0 else 1)
