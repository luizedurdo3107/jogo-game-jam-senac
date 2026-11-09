extends Control

var layout: VBoxContainer
var existing := false

func _ready() -> void:
	GameState.input_locked = true
	theme = SignalTheme.create()
	var background := TextureRect.new()
	background.texture = preload("res://assets/referencias/recife_aprovado.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)
	var veil := ColorRect.new()
	veil.color = Color(0.025,0.045,0.09,0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720,440)
	center.add_child(panel)
	layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",8)
	panel.add_child(layout)
	layout.add_child(SignalTheme.label("RECIFE ANTIGO / 2187 · 2.5D MOBILE",17,SignalTheme.TEAL))
	layout.add_child(SignalTheme.label("LAST SIGNAL: EARTH_404",32,SignalTheme.GOLD))
	var description := SignalTheme.label("Duas fases: Recife Antigo e Capibaribe.\nCorpo + GAIA. Uma escolha de água, dois futuros.",20)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 660
	layout.add_child(description)
	existing = not StationJourney.read_save().is_empty()
	var continuing := _button(layout,"Continuar jornada",func():StationJourney.enter(true))
	continuing.disabled = not existing
	var fresh := _button(layout,"Nova jornada",_new_game)
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation",12)
	layout.add_child(options)
	_button(options,"Áudio / volumes",func():AudioDirector.open_settings(self))
	_button(options,"Créditos",func():
		var credits := CanvasLayer.new()
		credits.set_script(preload("res://scripts/ui/release_credits.gd"))
		add_child(credits))
	layout.add_child(SignalTheme.label("Horizontal · Toque ou teclado · Sem combate\nA/D mover · W/S escadas · Espaço saltar · Q GAIA · E agir",16,SignalTheme.MUTED))
	if existing:continuing.grab_focus()
	else:fresh.grab_focus()
	AudioDirector.attach_world(self,"menu")

func _new_game() -> void:
	if not existing:
		StationJourney.enter(false)
		return
	for child in layout.get_children():
		layout.remove_child(child)
		child.queue_free()
	layout.add_child(SignalTheme.label("REINICIAR JORNADA?",28,SignalTheme.GOLD))
	layout.add_child(SignalTheme.label("Isso reinicia apenas esta campanha curta.\nOs arquivos de salvamento das edições anteriores são preservados.",20))
	_button(layout,"Cancelar",func():get_tree().reload_current_scene()).grab_focus()
	_button(layout,"Confirmar nova jornada",func():StationJourney.enter(false))

func _button(parent: Node, title: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.custom_minimum_size.y = 64
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(action)
	parent.add_child(result)
	return result
