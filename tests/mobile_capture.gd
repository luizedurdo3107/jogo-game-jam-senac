extends "res://tests/journey_test.gd"

func capture_image(filename: String) -> void:
	await frames(20)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://outputs/"+filename)

func run() -> void:
	StationJourney.persistence_enabled = false
	StationJourney.save_path = "user://short_capture_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	AudioDirector.persistence_enabled = false
	SceneRouter.test_mode = true
	DisplayServer.window_set_size(Vector2i(844,390))
	var title: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(title)
	await capture_image("SHORT_25D_MENU.png")
	title.queue_free()
	await frames(5)
	await open_demo()
	game.hud.touch.set_manual_mode(1)
	await capture_image("SHORT_25D_RECIFE.png")
	game.queue_free()
	await frames(5)
	seed_water()
	await open_station("water")
	game.hud.touch.set_manual_mode(1)
	game.player.position = Vector3(32,0.05,0)
	await frames(30)
	game.hud.show_signal_summary()
	await capture_image("SHORT_25D_TRANSMISSAO.png")
	game.queue_free()
	await frames(5)
	for choice in ["RESTORE","EXODUS"]:
		seed_water(choice)
		StationJourney.complete_signal()
		var epilogue: Node3D = load("res://scenes/regions/epilogue.tscn").instantiate()
		add_child(epilogue)
		await capture_image("SHORT_25D_FINAL_"+choice+".png")
		epilogue.queue_free()
		await frames(5)
	await AudioDirector.quit_game()
