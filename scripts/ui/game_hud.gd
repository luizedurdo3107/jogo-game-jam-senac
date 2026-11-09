extends CanvasLayer

var world: Node3D
var root: Control
var objective: Label
var perspective: Label
var context: Label
var toast: Label
var modal: PanelContainer
var modal_box: VBoxContainer
var touch: Control
var portrait: ColorRect
var modal_open := false
var muted := false
var toast_time := 0.0
var header: MarginContainer

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = SignalTheme.create()
	add_child(root)
	header = MarginContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16
	header.offset_right = -16
	header.offset_top = 14
	root.add_child(header)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	header.add_child(columns)
	var identity := PanelContainer.new()
	identity.custom_minimum_size.x = 210
	identity.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	columns.add_child(identity)
	var identity_box := VBoxContainer.new()
	identity.add_child(identity_box)
	identity_box.add_child(SignalTheme.label("LAST SIGNAL / EARTH_404", 17, SignalTheme.GOLD))
	perspective = SignalTheme.label("[F] FÍSICO / RECIFE · 2187", 14)
	identity_box.add_child(perspective)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(spacer)
	var mission := PanelContainer.new()
	mission.custom_minimum_size.x = 390
	columns.add_child(mission)
	var mission_box := VBoxContainer.new()
	mission.add_child(mission_box)
	objective = SignalTheme.label("", 18, SignalTheme.GOLD)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 350
	mission_box.add_child(objective)
	context = SignalTheme.label("Explore as escadas e os terminais.", 16)
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_box.add_child(context)
	var utility := HBoxContainer.new()
	columns.add_child(utility)
	button(utility,"?",show_help,Vector2(64,64))
	button(utility,"||",show_pause,Vector2(64,64))
	touch = Control.new()
	touch.set_script(preload("res://scripts/ui/mobile_controls.gd"))
	root.add_child(touch)
	touch.action_started.connect(_touch_action)
	toast = SignalTheme.label("", 16, SignalTheme.TEAL)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = 112
	toast.offset_left = 70
	toast.offset_right = -70
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(toast)
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left = -350
	modal.offset_right = 350
	modal.offset_top = -176
	modal.offset_bottom = 176
	root.add_child(modal)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal.add_child(scroll)
	modal_box = VBoxContainer.new()
	modal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_box.add_theme_constant_override("separation",14)
	scroll.add_child(modal_box)
	modal.minimum_size_changed.connect(func(): call_deferred("_fit_modal"))
	modal.hide()
	portrait = ColorRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.color = Color("101c2b")
	portrait.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(portrait)
	var rotate_text := SignalTheme.label("Vire o celular para jogar\nna horizontal.\n\nSua partida continua aqui.",42,SignalTheme.TEAL)
	rotate_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotate_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotate_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(rotate_text)
	portrait.hide()
	get_viewport().size_changed.connect(_resize)
	_resize()

func button(parent: Node, text: String, callback: Callable, minimum := Vector2(0,64)) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func _process(delta: float) -> void:
	var window_size := DisplayServer.window_get_size()
	if portrait.visible != (window_size.y>window_size.x):
		_resize()
	toast_time = maxf(0, toast_time - delta)
	toast.visible = toast_time > 0
	toast.offset_top = header.position.y+header.size.y+10
	if world:
		world.player.locked = world.finished or modal_open or portrait.visible

func _resize() -> void:
	touch._layout()
	header.offset_left = touch.safe_margin.x+2
	header.offset_right = -touch.safe_margin.x-2
	header.offset_top = touch.safe_top
	portrait.visible = DisplayServer.window_get_size().y > DisplayServer.window_get_size().x
	if portrait.visible:
		touch.release_all()
	call_deferred("_fit_modal")

func _fit_modal() -> void:
	modal.size = Vector2(minf(700,root.size.x-40),minf(root.size.y-32,maxf(352,modal_box.get_combined_minimum_size().y+40)))
	modal.position = (root.size-modal.size)*0.5

func _touch_action(action: String) -> void:
	if action == "interact":
		world.try_interact()
	elif action == "perspective":
		world.toggle_gaia()

func notify(text: String) -> void:
	toast.text = text
	toast_time = 4.5

func refresh() -> void:
	objective.text = world.current_objective()
	perspective.text = "[G] GAIA / ANÁLISE DIGITAL" if GameState.gaia_active else "[F] FÍSICO / RECIFE · 2187"
	perspective.modulate = SignalTheme.TEAL if GameState.gaia_active else SignalTheme.PAPER

func _clear_modal(title: String, text: String) -> void:
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()
	modal_box.add_child(SignalTheme.label(title,23,SignalTheme.TEAL))
	var body := SignalTheme.label(text,22)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_box.add_child(body)
	modal.show()
	modal_open = true
	world.player.locked = true
	touch.release_all()
	touch.controls_enabled = false
	touch.queue_redraw()

func close_modal() -> void:
	modal.hide()
	modal_open = false
	world.player.locked = portrait.visible
	touch.controls_enabled = true
	touch.queue_redraw()

func show_dialogue(title: String, text: String) -> void:
	_clear_modal(title,text)
	button(modal_box,"Continuar  [E / Enter]",close_modal).grab_focus()

func show_help() -> void:
	_clear_modal("DOIS OLHARES. UMA CIDADE.","Corpo: recolhe a célula e move mecanismos.\nGAIA: revela circuitos e autoriza sistemas.\n\nA/D ou < >: mover · Espaço: saltar\nW/S ou ^ v: escadas · E: agir · Q: GAIA\nAmarelo marca os caminhos entre alturas. Sem combate.")
	button(modal_box,"Voltar ao Recife",close_modal).grab_focus()

func show_pause() -> void:
	if world.finished:
		return
	_clear_modal("TRANSMISSÃO EM PAUSA","As ações e escolhas são salvas neste dispositivo. Checkpoint retorna ao último local seguro.")
	var row := HBoxContainer.new()
	modal_box.add_child(row)
	button(row,"Continuar",close_modal).grab_focus()
	button(row,"Checkpoint",world.restart)
	button(row,"Menu",world.menu)
	var controls := OptionButton.new()
	controls.add_item("Toque: automático")
	controls.add_item("Toque: sempre visível")
	controls.add_item("Toque: ocultar")
	controls.selected = touch.manual_mode
	controls.custom_minimum_size.y = 48
	controls.item_selected.connect(touch.set_manual_mode)
	modal_box.add_child(controls)
	var options := HBoxContainer.new()
	modal_box.add_child(options)
	button(options,"Áudio / volumes",func():AudioDirector.open_settings(self))
	button(options,"Gráficos: reduzido / normal",world.toggle_quality)
