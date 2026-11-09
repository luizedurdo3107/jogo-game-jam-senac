extends CanvasLayer

var previous_focus: WeakRef

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 95
	var focused := get_viewport().gui_get_focus_owner()
	if focused:previous_focus = weakref(focused)
	var overlay := ColorRect.new()
	overlay.color = Color(0.02,0.04,0.07,0.98)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = SignalTheme.create()
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700,430)
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	panel.add_child(layout)
	layout.add_child(SignalTheme.label("LAST SIGNAL: EARTH_404 / CRÉDITOS",24,SignalTheme.TEAL))
	var description := SignalTheme.label("Versão %s · Recife, 2187\n\nPersonagem e referências visuais: materiais fornecidos pelo responsável pelo projeto, preservados.\nProgramação e ferramentas: Godot 4 / GDScript.\nÁudio: sound design procedural original, sem TTS.\n\nCampanha curta 2.5D: Recife Antigo, Capibaribe e encerramento conforme o destino da água. Música e gravações humanas finais ainda não integram esta edição.\n\nGodot Engine — licença MIT: godotengine.org/license\nAvisos completos de terceiros acompanham a distribuição."%ProjectSettings.get_setting("application/config/version"),17)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 650
	layout.add_child(description)
	var close := Button.new()
	close.text = "Voltar [Esc]"
	close.custom_minimum_size.y = 44
	close.pressed.connect(dismiss)
	layout.add_child(close)
	close.grab_focus()
	AudioDirector.request_duck(self,"dialogue")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		dismiss()
		get_viewport().set_input_as_handled()

func dismiss() -> void:
	if previous_focus and is_instance_valid(previous_focus.get_ref()):previous_focus.get_ref().grab_focus()
	queue_free()

func _exit_tree() -> void:
	AudioDirector.release_duck(get_instance_id())
