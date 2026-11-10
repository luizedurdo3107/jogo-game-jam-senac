extends Control

signal action_started(action: String)
var buttons: Dictionary = {}
var fingers: Dictionary = {}
var manual_mode := 0
var controls_enabled := true
var safe_margin := Vector2(14, 10)
var safe_top := 14.0
var font: Font
var browser_touch := false
var persistence_enabled := true
var combat_enabled := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = ThemeDB.fallback_font
	var preferences := ConfigFile.new()
	if preferences.load("user://mobile_controls.cfg")==OK:
		manual_mode = clampi(int(preferences.get_value("touch","mode",0)),0,2)
	if OS.has_feature("web"):
		browser_touch = bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 && matchMedia('(pointer: coarse)').matches",true))
	resized.connect(_layout)
	_layout()

func set_manual_mode(mode: int) -> void:
	manual_mode = clampi(mode,0,2)
	var preferences := ConfigFile.new()
	preferences.set_value("touch","mode",manual_mode)
	if persistence_enabled:preferences.save("user://mobile_controls.cfg")
	release_all()
	queue_redraw()

func should_show() -> bool:
	return manual_mode == 1 or manual_mode == 0 and (browser_touch if OS.has_feature("web") else DisplayServer.is_touchscreen_available())

func _layout() -> void:
	var screen_size := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen_size.x > 0 and safe.size.x > 0 and not OS.has_feature("web"):
		safe_margin.x = maxf(14, safe.position.x * size.x / screen_size.x)
	if OS.has_feature("web") and screen_size.x > 0:
		var scale_factor := size.x/screen_size.x
		safe_margin.x = maxf(14,maxf(_browser_inset("left"),_browser_inset("right"))*scale_factor+8)
		safe_margin.y = maxf(10,_browser_inset("bottom")*scale_factor+8)
		safe_top = maxf(14,_browser_inset("top")*scale_factor+8)
	var bottom := size.y - 84 - safe_margin.y
	var left := safe_margin.x + 4
	buttons = {
		"move_left":{"rect":Rect2(left,bottom,72,72),"text":"<","hint":"MOVER"},
		"move_right":{"rect":Rect2(left+82,bottom,72,72),"text":">","hint":""},
		"climb_up":{"rect":Rect2(left+164,bottom-55,60,60),"text":"^","hint":"SUBIR"},
		"climb_down":{"rect":Rect2(left+164,bottom+12,60,60),"text":"v","hint":"DESCER"},
		"perspective":{"rect":Rect2(size.x-safe_margin.x-242,bottom,72,72),"text":"Q","hint":"GAIA"},
		"jump":{"rect":Rect2(size.x-safe_margin.x-160,bottom-55,72,72),"text":"^","hint":"SALTAR"},
		"interact":{"rect":Rect2(size.x-safe_margin.x-78,bottom,78,72),"text":"E","hint":"AGIR"}
	}
	if combat_enabled:
		buttons.erase("perspective")
		buttons.attack = {"rect":Rect2(size.x-safe_margin.x-242,bottom,72,72),"text":"F","hint":"GOLPE"}
	queue_redraw()

func _browser_inset(edge: String) -> float:
	var pixels: Variant = JavaScriptBridge.eval("parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--safe-%s')) || 0"%edge,true)
	return float(pixels) if pixels is float or pixels is int else 0.0

func _input(event: InputEvent) -> void:
	if not should_show() or not controls_enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			for action in buttons:
				if buttons[action].rect.has_point(event.position):
					fingers[event.index] = action
					Input.action_press(action)
					action_started.emit(action)
					get_viewport().set_input_as_handled()
					break
		else:
			_release(event.index)
		queue_redraw()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var action: String = fingers[event.index]
		if not buttons[action].rect.grow(18).has_point(event.position):
			_release(event.index)
		queue_redraw()

func _release(index: int) -> void:
	if not fingers.has(index):
		return
	var action: String = fingers[index]
	fingers.erase(index)
	if not fingers.values().has(action):
		Input.action_release(action)

func release_all() -> void:
	for action in fingers.values():
		Input.action_release(action)
	fingers.clear()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()

func _draw() -> void:
	if not should_show() or not controls_enabled:
		return
	for action in buttons:
		var data: Dictionary = buttons[action]
		var rect: Rect2 = data.rect
		var pressed := fingers.values().has(action)
		draw_style_box(SignalTheme.box(Color("345c69") if pressed else Color(0.035,0.08,0.13,0.84),SignalTheme.TEAL if pressed else Color("617286"),0),rect)
		draw_string(font,rect.position+Vector2(23,43),data.text,HORIZONTAL_ALIGNMENT_LEFT,-1,29,SignalTheme.PAPER)
		if not str(data.hint).is_empty():
			draw_string(font,rect.position+Vector2(4,-8),data.hint,HORIZONTAL_ALIGNMENT_LEFT,-1,12,SignalTheme.PAPER)
