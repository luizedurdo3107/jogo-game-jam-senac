extends Control

const CYAN := Color("82ead7")
const MAGENTA := Color("e975b9")
const NIGHT := Color("0a1420")

var layout: VBoxContainer
var existing := false
var background: TextureRect
var menu_scroll: ScrollContainer
var location: VBoxContainer
var masthead: HBoxContainer
var footer: HBoxContainer
var fresh: Button
var continuing: Button
var confirmation: Control
var confirmation_panel: PanelContainer
var cancel_new: Button
var confirm_new: Button
var status: ColorRect
var elapsed := 0.0

func _ready() -> void:
	GameState.input_locked = true
	theme = SignalTheme.create()
	background = TextureRect.new()
	background.texture = preload("res://assets/referencias_aprovadas/09_recife_antigo_2187_identidade_local.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_veil([0.0,0.36,0.7,1.0],[Color(0.02,0.04,0.08,0.97),Color(0.02,0.04,0.08,0.88),Color(0.02,0.04,0.08,0.16),Color(0.02,0.04,0.08,0.08)],false)
	_veil([0.0,0.55,1.0],[Color(0.02,0.04,0.08,0.2),Color(0.02,0.04,0.08,0),Color(0.02,0.04,0.08,0.92)],true)
	_build_frame()
	menu_scroll = ScrollContainer.new()
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(menu_scroll)
	layout = VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation",8)
	menu_scroll.add_child(layout)
	_build_home()
	_build_location()
	_build_confirmation()
	resized.connect(_reflow)
	_reflow()
	menu_scroll.modulate.a = 0
	create_tween().tween_property(menu_scroll,"modulate:a",1.0,0.7)
	AudioDirector.attach_world(self,"menu")

func _veil(offsets: Array, colors: Array, vertical: bool) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0,1) if vertical else Vector2(1,0)
	var overlay := TextureRect.new()
	overlay.texture = texture
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func _build_frame() -> void:
	masthead = HBoxContainer.new()
	masthead.add_theme_constant_override("separation",12)
	add_child(masthead)
	status = ColorRect.new()
	status.color = CYAN
	status.custom_minimum_size = Vector2(4,12)
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	masthead.add_child(status)
	masthead.add_child(SignalTheme.label("SINAL LOCAL  /  RECIFE, 2187",13,CYAN))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	masthead.add_child(spacer)
	masthead.add_child(SignalTheme.label("EARTH_404  ·  "+str(ProjectSettings.get_setting("application/config/version")),12,SignalTheme.MUTED))
	footer = HBoxContainer.new()
	add_child(footer)
	footer.add_child(SignalTheme.label("COMBATE  /  EXPLORAÇÃO  /  ESCOLHAS",11,SignalTheme.MUTED))
	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	footer.add_child(SignalTheme.label("ÁGUA  /  SOLO  /  AR",11,CYAN))

func _build_home() -> void:
	var title := SignalTheme.label("LAST SIGNAL",52,Color("f1ede5"))
	var display_font := FontVariation.new()
	display_font.base_font = ThemeDB.fallback_font
	display_font.variation_embolden = 0.7
	title.add_theme_font_override("font",display_font)
	layout.add_child(title)
	layout.add_child(SignalTheme.label("E A R T H _ 4 0 4",20,CYAN))
	var rule := ColorRect.new()
	rule.color = MAGENTA
	rule.custom_minimum_size = Vector2(72,3)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	layout.add_child(rule)
	var description := SignalTheme.label("O mundo ainda responde.\nQue futuro você vai escolher?",18,SignalTheme.PAPER)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(description)
	var space := Control.new()
	space.custom_minimum_size.y = 8
	layout.add_child(space)
	existing = not StationJourney.read_save().is_empty()
	continuing = _button(layout,"Continuar jornada",func():StationJourney.enter(true),existing)
	continuing.disabled = not existing
	continuing.tooltip_text = "Retomar o último progresso salvo." if existing else "Seu progresso aparecerá aqui depois de iniciar a jornada."
	fresh = _button(layout,"Nova jornada",_new_game,not existing)
	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation",10)
	layout.add_child(options)
	var audio := _button(options,"Áudio",func():AudioDirector.open_settings(self))
	audio.custom_minimum_size.y = 42
	var credits := _button(options,"Créditos",_show_credits)
	credits.custom_minimum_size.y = 42
	if existing:continuing.grab_focus()
	else:fresh.grab_focus()

func _build_location() -> void:
	location = VBoxContainer.new()
	location.mouse_filter = Control.MOUSE_FILTER_IGNORE
	location.add_theme_constant_override("separation",10)
	add_child(location)
	location.add_child(SignalTheme.label("01  /  O ÚLTIMO SINAL",12,CYAN))
	var message := SignalTheme.label("Ainda há vida\nno fim do mundo.",27,SignalTheme.PAPER)
	message.add_theme_font_override("font",ThemeDB.fallback_font)
	location.add_child(message)
	location.add_child(SignalTheme.label("RECIFE ANTIGO · BRASIL",12,SignalTheme.MUTED))

func _build_confirmation() -> void:
	confirmation = Control.new()
	confirmation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(confirmation)
	var veil := ColorRect.new()
	veil.color = Color(0.015,0.025,0.045,0.92)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirmation.add_child(veil)
	confirmation_panel = PanelContainer.new()
	confirmation_panel.add_theme_stylebox_override("panel",SignalTheme.box(NIGHT,CYAN,24))
	confirmation.add_child(confirmation_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	confirmation_panel.add_child(scroll)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation",16)
	scroll.add_child(words)
	words.add_child(SignalTheme.label("INICIAR UM NOVO SINAL?",24,CYAN))
	var warning := SignalTheme.label("O progresso desta jornada será reiniciado.\nOs salvamentos das edições anteriores continuam preservados.",18)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(warning)
	cancel_new = _button(words,"Manter minha jornada",_cancel_new_game,true)
	confirm_new = _button(words,"Confirmar nova jornada",func():StationJourney.enter(false))
	confirmation.hide()

func _reflow() -> void:
	if not is_instance_valid(menu_scroll):return
	var compact := size.x/size.y<1.4
	var margin := 28.0 if compact else 48.0
	masthead.position = Vector2(margin,24)
	masthead.size = Vector2(size.x-margin*2,28)
	masthead.get_child(3).visible = not compact
	footer.position = Vector2(margin,size.y-35)
	footer.size = Vector2(size.x-margin*2,20)
	footer.get_child(2).visible = not compact
	var width := minf(430,size.x-margin*2)
	menu_scroll.position = Vector2((size.x-width)*0.5 if compact else margin,82 if compact else 92)
	menu_scroll.size = Vector2(width,size.y-menu_scroll.position.y-64)
	location.visible = not compact and size.x>=900
	location.position = Vector2(size.x-300,size.y-190)
	location.size = Vector2(270,140)
	confirmation_panel.size = Vector2(minf(540,size.x-48),330)
	confirmation_panel.position = (size-confirmation_panel.size)*0.5

func _process(delta: float) -> void:
	elapsed += delta
	background.position = Vector2(-12+sin(elapsed*0.045)*8,-9)
	background.size = size+Vector2(30,24)
	status.modulate.a = 0.65+sin(elapsed*1.8)*0.25

func _new_game() -> void:
	if not existing:
		StationJourney.enter(false)
		return
	confirmation.show()
	_reflow()
	cancel_new.grab_focus()

func _cancel_new_game() -> void:
	confirmation.hide()
	fresh.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if confirmation.visible and event.is_action_pressed("ui_cancel"):
		_cancel_new_game()
		get_viewport().set_input_as_handled()

func _show_credits() -> void:
	var credits := CanvasLayer.new()
	credits.set_script(preload("res://scripts/ui/release_credits.gd"))
	add_child(credits)

func _button(parent: Node, title: String, action: Callable, primary := false) -> Button:
	var result := Button.new()
	result.text = title
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.custom_minimum_size.y = 52
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_theme_font_size_override("font_size",18)
	result.add_theme_stylebox_override("normal",SignalTheme.box(CYAN if primary else Color(0.035,0.075,0.12,0.8),CYAN if primary else Color("3b5363"),14))
	result.add_theme_stylebox_override("hover",SignalTheme.box(Color("c1f6e7") if primary else Color("1c3643"),CYAN,14))
	result.add_theme_stylebox_override("pressed",SignalTheme.box(Color("57b4ab"),CYAN,14))
	result.add_theme_stylebox_override("focus",SignalTheme.box(Color(0,0,0,0),MAGENTA,14))
	if primary:
		for color_name in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:result.add_theme_color_override(color_name,NIGHT)
	result.pressed.connect(action)
	parent.add_child(result)
	return result
