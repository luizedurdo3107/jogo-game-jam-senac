extends Node3D

var environment: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var return_button: Button

func _ready() -> void:
	if StationJourney.stage!="ending" or StationJourney.ending().is_empty() or StationJourney.value("signal_sent")!=1:
		SceneRouter.menu()
		return
	GameState.gaia_active = false
	var ending := StationJourney.ending()
	environment = Node3D.new()
	environment.set_script(preload("res://scripts/environments/recife_environment.gd"))
	add_child(environment)
	environment.show_decision(ending=="ending_a")
	player = CharacterBody3D.new()
	player.set_script(preload("res://scripts/game/player_controller.gd"))
	player.world = environment
	player.position = Vector3(5,0.1,0)
	player.locked = true
	add_child(player)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.position = Vector3(8,8,22)
	add_child(camera)
	camera.look_at(Vector3(6,2,-1))
	hud = CanvasLayer.new()
	add_child(hud)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",32)
	margin.add_theme_constant_override("margin_right",32)
	margin.add_theme_constant_override("margin_top",24)
	margin.add_theme_constant_override("margin_bottom",24)
	margin.theme = SignalTheme.create()
	hud.add_child(margin)
	var panel := PanelContainer.new()
	margin.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation",12)
	scroll.add_child(layout)
	var endings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/endings.json"))
	var story: Dictionary = endings[ending]
	layout.add_child(SignalTheme.label(str(story.chapter),19,SignalTheme.TEAL))
	layout.add_child(SignalTheme.label(str(story.title),32,SignalTheme.GOLD))
	var text := SignalTheme.label(str(story.text).replace("{player}",GameState.player_name),22)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(text)
	layout.add_child(SignalTheme.label("Água: "+("Recife / restauração comunitária" if StationJourney.choices.water=="RESTORE" else "ARCA-01 / reservatórios de evacuação"),18,SignalTheme.TEAL))
	var menu := Button.new()
	menu.text = "Fim da transmissão · Voltar ao menu"
	menu.custom_minimum_size.y = 64
	return_button = menu
	menu.pressed.connect(SceneRouter.menu)
	content.add_child(menu)
	menu.grab_focus()
	AudioDirector.attach_world(self,ending)
