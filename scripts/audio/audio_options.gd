extends CanvasLayer

var sliders: Dictionary = {}
var percentages: Dictionary = {}
var previous_focus: WeakRef
var overlay: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	var focused := get_viewport().gui_get_focus_owner()
	if focused:previous_focus = weakref(focused)
	overlay = ColorRect.new()
	overlay.color = Color(0.02,0.04,0.07,0.96)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme = SignalTheme.create()
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700,460)
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",9)
	panel.add_child(layout)
	layout.add_child(SignalTheme.label("ÁUDIO / O SOM DO RECIFE",24,SignalTheme.TEAL))
	layout.add_child(SignalTheme.label("Preferências independentes · salvas neste dispositivo",14,SignalTheme.MUTED))
	var names := {"Master":"Geral","Music":"Música","Ambience":"Ambiente","SFX":"Efeitos","UI":"Interface","Voice":"Vozes humanas"}
	for bus in AudioDirector.BUSES:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 36
		layout.add_child(row)
		var label := SignalTheme.label(names[bus],17)
		label.custom_minimum_size.x = 170
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = AudioDirector.levels[bus]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.accessibility_name = "Volume "+names[bus]
		row.add_child(slider)
		var percentage := SignalTheme.label("%d%%"%roundi(slider.value*100),16,SignalTheme.TEAL)
		percentage.custom_minimum_size.x = 58
		row.add_child(percentage)
		sliders[bus] = slider
		percentages[bus] = percentage
		slider.value_changed.connect(func(value: float):
			AudioDirector.set_volume(bus,value)
			percentage.text = "%d%%"%roundi(value*100))
	layout.add_child(SignalTheme.label("Sem dublagem artificial. Música e gravações humanas ainda não fornecidas.",13,SignalTheme.MUTED))
	var preview := Button.new()
	preview.text = "Testar efeito mecânico / efeitos"
	preview.custom_minimum_size.y = 40
	preview.pressed.connect(func():AudioDirector.ui("valve"))
	layout.add_child(preview)
	var close := Button.new()
	close.text = "Voltar [Esc]"
	close.custom_minimum_size.y = 44
	close.pressed.connect(dismiss)
	layout.add_child(close)
	AudioDirector.request_duck(self,"paused")
	sliders.Master.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		dismiss()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("perspective") or event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()

func dismiss() -> void:
	if previous_focus and is_instance_valid(previous_focus.get_ref()) and previous_focus.get_ref().is_inside_tree():previous_focus.get_ref().grab_focus()
	queue_free()

func _exit_tree() -> void:
	AudioDirector.release_duck(get_instance_id())
