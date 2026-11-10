extends "res://tests/flow_test.gd"

func run() -> void:
	DisplayServer.window_set_size(Vector2i(844,390))
	await super.run()
