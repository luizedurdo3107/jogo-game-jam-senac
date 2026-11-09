extends "res://tests/journey_test.gd"

func capture_image(filename: String) -> void:
	await frames(20)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://outputs/"+filename)

func run() -> void:
	StationJourney.persistence_enabled = false
	AudioDirector.persistence_enabled = false
	SceneRouter.test_mode = true
	DisplayServer.window_set_size(Vector2i(844,390))
	var title: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(title)
	await capture_image("MOBILE_25D_MENU.png")
	title.queue_free()
	await frames(5)
	await open_demo()
	game.hud.touch.set_manual_mode(1)
	game.player.position = Vector3(6,0.05,0)
	await capture_image("MOBILE_25D_RECIFE.png")
	game.queue_free()
	await frames(5)
	seed_choices(7)
	await open_station("nexus")
	game.hud.touch.set_manual_mode(1)
	game.player.position = Vector3(19,0.05,0)
	await capture_image("MOBILE_25D_NEXUS_FISICO.png")
	game.toggle_gaia()
	await capture_image("MOBILE_25D_NEXUS_GAIA.png")
	game.queue_free()
	await frames(5)
	for flag in ["nexus_voss","nexus_scan","nexus_locks","nexus_authorized","nexus_open"]:StationJourney.put(flag,1)
	StationJourney.complete_nexus()
	var epilogue: Node3D = load("res://scenes/regions/epilogue.tscn").instantiate()
	add_child(epilogue)
	await capture_image("MOBILE_25D_FINAL.png")
	epilogue.queue_free()
	await frames(5)
	await AudioDirector.quit_game()
