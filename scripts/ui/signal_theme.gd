class_name SignalTheme
extends RefCounted

const INK := Color("101d29")
const PAPER := Color("e3ded3")
const MUTED := Color("b0a9b9")
const GOLD := Color("dcc28b")
const TEAL := Color("8ad6c4")

static func box(color: Color, border: Color = Color("474252"), margin := 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func create() -> Theme:
	var result: Theme = preload("res://assets/processados/interface/industrial_theme.tres").duplicate(true)
	result.default_font_size = 20
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_hover_color", "Button", TEAL)
	result.set_color("font_focus_color", "Button", TEAL)
	result.set_color("font_disabled_color", "Button", Color("777080"))
	result.set_stylebox("normal", "Button", box(Color("20323f")))
	result.set_stylebox("hover", "Button", box(Color("304553"), TEAL))
	result.set_stylebox("pressed", "Button", box(Color("3d4550"), GOLD))
	result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), TEAL))
	result.set_stylebox("disabled", "Button", box(Color("1b1b27")))
	result.set_stylebox("panel", "PanelContainer", box(INK))
	result.set_stylebox("panel", "Panel", box(INK))
	return result

static func label(text: String, size := 17, color: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
