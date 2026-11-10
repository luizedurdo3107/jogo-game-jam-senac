extends Control

var shots: Array = []
var shot := -1
var elapsed := 0.0
var current: TextureRect
var previous: TextureRect
var subtitle: Label
var chapter: Label
var skip: Button
var duration := 0.0
var completed := false

func _ready() -> void:
	theme = SignalTheme.create()
	GameState.input_locked = true
	shots = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/intro.json"))
	for layer_index in range(2):
		var picture := TextureRect.new()
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(picture)
		if layer_index==0:previous = picture
		else:current = picture
	var bottom := PanelContainer.new()
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -150
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_bottom = -24
	add_child(bottom)
	var words := VBoxContainer.new()
	bottom.add_child(words)
	chapter = SignalTheme.label("",18,SignalTheme.TEAL)
	words.add_child(chapter)
	subtitle = SignalTheme.label("",27)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(subtitle)
	skip = Button.new()
	skip.text = "Pular introdução  [Esc]"
	skip.position = Vector2(24,24)
	skip.custom_minimum_size = Vector2(280,58)
	skip.pressed.connect(finish)
	add_child(skip)
	AudioDirector.attach_world(self,"nova_eden")
	_next()

func _process(delta: float) -> void:
	if completed:return
	elapsed += delta
	current.modulate.a = minf(1,elapsed/1.2)
	var progress := clampf(elapsed/duration,0,1)
	var zoom := 1.02+progress*0.055
	current.pivot_offset = size*0.5
	current.scale = Vector2.ONE*zoom
	current.position.x = sin(float(shot))*progress*14
	if elapsed>=duration:_next()

func _next() -> void:
	shot += 1
	if shot>=shots.size():
		finish()
		return
	var entry: Dictionary = shots[shot]
	previous.texture = current.texture
	current.texture = load(str(entry.image))
	current.modulate.a = 0
	elapsed = 0
	duration = float(entry.seconds)
	chapter.text = str(entry.title)
	subtitle.text = str(entry.text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		finish()

func finish() -> void:
	if completed:return
	completed = true
	StationJourney.finish_intro()
