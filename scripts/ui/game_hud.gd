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
var interaction_panel: PanelContainer
var viewing_memory := false

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
	identity_box.add_child(SignalTheme.label("PRESENTE / RECIFE · 2187", 17, SignalTheme.GOLD))
	perspective = SignalTheme.label("[F] CORPO", 18)
	identity_box.add_child(perspective)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(spacer)
	var mission := PanelContainer.new()
	mission.custom_minimum_size.x = 340
	columns.add_child(mission)
	var mission_box := VBoxContainer.new()
	mission.add_child(mission_box)
	objective = SignalTheme.label("", 20, SignalTheme.GOLD)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 300
	mission_box.add_child(objective)
	context = SignalTheme.label("Aproxime-se para interagir.", 18)
	context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_panel = PanelContainer.new()
	interaction_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	interaction_panel.offset_left = 160
	interaction_panel.offset_right = -160
	interaction_panel.offset_top = -90
	interaction_panel.offset_bottom = -28
	root.add_child(interaction_panel)
	interaction_panel.add_child(context)
	var utility := HBoxContainer.new()
	columns.add_child(utility)
	button(utility,"?",show_help,Vector2(64,64))
	button(utility,"||",show_pause,Vector2(64,64))
	touch = Control.new()
	touch.set_script(preload("res://scripts/ui/mobile_controls.gd"))
	root.add_child(touch)
	touch.action_started.connect(_touch_action)
	toast = SignalTheme.label("", 20, SignalTheme.TEAL)
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
	result.tooltip_text = text
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.custom_minimum_size = minimum
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func _process(delta: float) -> void:
	var window_size := DisplayServer.window_get_size()
	if portrait.visible != (touch.should_show() and window_size.y>window_size.x):
		_resize()
	if not modal_open:toast_time = maxf(0, toast_time - delta)
	toast.visible = toast_time > 0 and not modal_open
	header.visible = not modal_open
	interaction_panel.visible = not modal_open and not portrait.visible
	interaction_panel.offset_top = -215 if touch.should_show() else -88
	interaction_panel.offset_bottom = -153 if touch.should_show() else -26
	toast.offset_top = header.position.y+header.size.y+10
	if world:
		world.player.locked = world.finished or modal_open or portrait.visible

func _resize() -> void:
	touch._layout()
	header.offset_left = touch.safe_margin.x+2
	header.offset_right = -touch.safe_margin.x-2
	header.offset_top = touch.safe_top
	portrait.visible = touch.should_show() and DisplayServer.window_get_size().y > DisplayServer.window_get_size().x
	if portrait.visible:
		touch.release_all()
	call_deferred("_fit_modal")

func _fit_modal() -> void:
	modal.size = Vector2(minf(700,root.size.x-40),minf(root.size.y-32,maxf(352,modal_box.get_combined_minimum_size().y+40)))
	modal.position = (root.size-modal.size)*0.5

func _touch_action(action: String) -> void:
	if action=="attack" and world.has_method("attack"):
		world.attack()
	elif action == "interact":
		world.try_interact()
	elif action == "perspective":
		world.toggle_gaia()

func notify(text: String) -> void:
	toast.text = text
	toast_time = 4.5

func refresh() -> void:
	objective.text = world.current_objective()
	perspective.text = "[Q] GAIA · CIRCUITOS" if GameState.gaia_active else "[Q] CORPO · OBJETOS"
	perspective.modulate = SignalTheme.TEAL if GameState.gaia_active else SignalTheme.PAPER

func _clear_modal(title: String, text: String) -> void:
	viewing_memory = false
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()
	var heading := SignalTheme.label(title,23,SignalTheme.TEAL)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_box.add_child(heading)
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
	if viewing_memory:
		world.perspectives.memory.hide()
		notify("PRESENTE / 2187. O arquivo foi fechado; suas ações continuam no Recife de agora.")
	viewing_memory = false
	modal.hide()
	modal_open = false
	world.player.locked = portrait.visible
	touch.controls_enabled = true
	touch.queue_redraw()

func show_dialogue(title: String, text: String) -> void:
	_clear_modal("PRESENTE / "+title,text)
	button(modal_box,"Continuar  [E / Enter]",close_modal).grab_focus()

func show_memory(title: String, text: String) -> void:
	_clear_modal("PASSADO / "+title,text+"\n\nArquivo reconstruído: você apenas consulta o que aconteceu. Nada aqui muda o passado.")
	viewing_memory = true
	button(modal_box,"Fechar arquivo · Voltar ao presente",close_modal).grab_focus()

func show_timeline() -> void:
	var timeline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/timeline.json"))
	_clear_modal("ENTENDA A LINHA DO TEMPO","\n\n".join([str(timeline.past),str(timeline.present),str(timeline.future)]))
	button(modal_box,"Continuar no presente",close_modal).grab_focus()

func show_help() -> void:
	if world.region_id=="nova_eden":
		_clear_modal("NOVA ÉDEN / ARSENAL E COMBATE","Abra o arsenal pela etiqueta dos três relés e pegue o bastão de pulso. Socos não atravessam as armaduras.\n\nA/D: mover · F: bastão · Espaço: esquivar. Três golpes esgotam o fôlego: recue para recuperar. Amarelo avisa; vermelho golpeia. O capitão bloqueia durante a preparação: ataque após o combo.\n\nDifícil: 4 de vida, dois soldados pressionando e combo do capitão. Padrão: 6 de vida e um inimigo por vez. Troque na pausa. Derrotados e arma permanecem no checkpoint.")
	elif world.region_id=="boss":
		_clear_modal("TERRA / COMBATE ANTES DO EMBARQUE","O exército de Nova Éden impede a saída para Marte. Enfrente dois soldados e o comandante usando o bastão: F golpeia, Espaço salta; recue para recuperar fôlego. No Difícil, o comandante tem 8 de vida e dois golpes por combo. Ataque na recuperação. Troque a dificuldade na pausa.\n\nVencida a guarnição, use Q/E nos comandos locais para desligar a contenção e confirmar o embarque. GAIA permanece restaurando a Terra: não ajuda a fuga nem é um alvo da luta. Derrotados e travas ficam no checkpoint.")
	else:
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
	if world.region_id in ["nova_eden","boss"]:
		var difficulty := OptionButton.new()
		difficulty.add_item("Combate: padrão / 6 de vida")
		difficulty.add_item("Combate: difícil / 4 de vida + dupla")
		difficulty.selected = StationJourney.value("nova_difficulty")
		difficulty.custom_minimum_size.y = 48
		difficulty.item_selected.connect(func(index: int):world.set_combat_difficulty(index==1))
		modal_box.add_child(difficulty)
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
	button(modal_box,"Passado, presente e futuro",show_timeline)
