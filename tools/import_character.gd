extends SceneTree

const RAW_DIRECTORY := "res://work/personagem_frames"
const OUTPUT_DIRECTORY := "res://assets/processados/protagonista_provisorio"
const FRAME_COUNT := 8
const BLACK_THRESHOLD := 14.0 / 255.0
const PADDING := 4

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var frames: Array[Image] = []
	var bounds: Array[Rect2i] = []
	var combined := Rect2i()
	for index in range(FRAME_COUNT):
		var image := Image.load_from_file("%s/frame_%02d.png" % [RAW_DIRECTORY, index + 1])
		if image == null or image.get_size() != Vector2i(368, 368):
			push_error("Quadro ausente ou com dimensão inesperada: %d" % (index + 1))
			quit(1)
			return
		image.convert(Image.FORMAT_RGBA8)
		_clear_connected_background(image)
		var used := image.get_used_rect()
		if used.size.x < 20 or used.size.y < 80:
			push_error("Recorte sem personagem suficiente: %d" % (index + 1))
			quit(1)
			return
		bounds.append(used)
		combined = used if index == 0 else combined.merge(used)
		frames.append(image)
	var baseline := combined.end.y
	var aligned_bounds := Rect2i()
	for index in range(frames.size()):
		var aligned := Image.create(368, 368, false, Image.FORMAT_RGBA8)
		var vertical_offset := baseline - bounds[index].end.y
		aligned.blit_rect(frames[index], bounds[index], bounds[index].position + Vector2i(0, vertical_offset))
		frames[index] = aligned
		var used := aligned.get_used_rect()
		aligned_bounds = used if index == 0 else aligned_bounds.merge(used)
	var crop := aligned_bounds.grow(PADDING).intersection(Rect2i(0, 0, 368, 368))
	var sheet := Image.create(crop.size.x * FRAME_COUNT, crop.size.y, false, Image.FORMAT_RGBA8)
	for index in range(frames.size()):
		sheet.blit_rect(frames[index], crop, Vector2i(index * crop.size.x, 0))
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIRECTORY)
	if sheet.save_png(OUTPUT_DIRECTORY + "/personagem.png") != OK:
		push_error("Falha ao salvar o sprite sheet")
		quit(1)
		return
	var manifest := {
		"source": "res://assets/originais/protagonista_provisorio/WhatsApp Video 2026-11-06 at 14.16.40.mp4",
		"source_sha256": FileAccess.get_sha256("res://assets/originais/protagonista_provisorio/WhatsApp Video 2026-11-06 at 14.16.40.mp4"),
		"source_width": 368,
		"source_height": 368,
		"duration_seconds": 0.8,
		"fps": 10,
		"frames": FRAME_COUNT,
		"frame_width": crop.size.x,
		"frame_height": crop.size.y,
		"padding": PADDING,
		"crop_x": crop.position.x,
		"crop_y": crop.position.y,
		"baseline_source_y": baseline,
		"background_threshold_rgb": 14,
		"background_method": "near-black flood fill connected to image border; enclosed dark details preserved",
		"alignment": "common crop and integer vertical foot alignment; no resampling",
		"animation_limit": "short source motion reused for idle and walk; no independent walk cycle supplied"
	}
	var file := FileAccess.open(OUTPUT_DIRECTORY + "/importacao.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("PERSONAGEM IMPORTADO: ", JSON.stringify(manifest))
	quit()

func _clear_connected_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue := PackedInt32Array()
	queue.resize(width * height)
	var tail := 0
	for column in range(width):
		tail = _enqueue(image, column, visited, queue, tail)
		tail = _enqueue(image, (height - 1) * width + column, visited, queue, tail)
	for row in range(height):
		tail = _enqueue(image, row * width, visited, queue, tail)
		tail = _enqueue(image, row * width + width - 1, visited, queue, tail)
	var head := 0
	while head < tail:
		var pixel_index := queue[head]
		head += 1
		var column := pixel_index % width
		var row := pixel_index / width
		image.set_pixel(column, row, Color(0, 0, 0, 0))
		if column > 0:
			tail = _enqueue(image, pixel_index - 1, visited, queue, tail)
		if column < width - 1:
			tail = _enqueue(image, pixel_index + 1, visited, queue, tail)
		if row > 0:
			tail = _enqueue(image, pixel_index - width, visited, queue, tail)
		if row < height - 1:
			tail = _enqueue(image, pixel_index + width, visited, queue, tail)

func _enqueue(image: Image, pixel_index: int, visited: PackedByteArray, queue: PackedInt32Array, tail: int) -> int:
	if visited[pixel_index] != 0:
		return tail
	visited[pixel_index] = 1
	var pixel := image.get_pixel(pixel_index % image.get_width(), pixel_index / image.get_width())
	if maxf(pixel.r, maxf(pixel.g, pixel.b)) <= BLACK_THRESHOLD:
		queue[tail] = pixel_index
		return tail + 1
	return tail
