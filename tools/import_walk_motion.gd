extends SceneTree

const SOURCE := "res://assets/originais/movimento_20261109/WhatsApp Video 2026-11-09 at 10.49.07.mp4"
const OUTPUT := "res://assets/processados/movimento_20261109"
const COUNT := 12

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var frames: Array[Image] = []
	var bounds := Rect2i()
	for index in range(COUNT):
		var frame := Image.load_from_file("res://work/restoration_motion/frame_%03d.png"%(index+1))
		if not frame:
			push_error("Extraia primeiro os quadros do vídeo com ffmpeg a 12 fps, 432×432.")
			quit(1)
			return
		frame.convert(Image.FORMAT_RGBA8)
		clear_background(frame)
		var used := frame.get_used_rect()
		bounds = used if index==0 else bounds.merge(used)
		frames.append(frame)
	var canvas := bounds.grow(4)
	var width := roundi(float(canvas.size.x)*216.0/canvas.size.y)
	var sheet := Image.create(width*COUNT,216,false,Image.FORMAT_RGBA8)
	for index in range(COUNT):
		var source := frames[index]
		var aligned := Image.create(canvas.size.x,canvas.size.y,false,Image.FORMAT_RGBA8)
		var used := source.get_used_rect()
		aligned.blit_rect(source,used,used.position-canvas.position+Vector2i(0,bounds.end.y-used.end.y))
		aligned.resize(width,216,Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(aligned,Rect2i(0,0,width,216),Vector2i(index*width,0))
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	sheet.save_png(OUTPUT+"/walk.png")
	var manifest := {"source":SOURCE,"source_sha256":FileAccess.get_sha256(SOURCE),"frames":COUNT,"fps":12,"frame_width":width,"frame_height":216,"method":"Border-connected near-white flood fill; enclosed pale face and clothing preserved. Common bounds, foot alignment, nearest-neighbour scaling.","limits":"Walk supplied by team video. Original idle retained. Jump/climb use held poses; no independent source cycles supplied. Video soundtrack is not used."}
	var file := FileAccess.open(OUTPUT+"/importacao.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	file.close()
	var resource := "[gd_resource type=\"SpriteFrames\" load_steps=23 format=3]\n\n[ext_resource type=\"Texture2D\" path=\"res://assets/processados/protagonista_provisorio/personagem.png\" id=\"1\"]\n[ext_resource type=\"Texture2D\" path=\"res://assets/processados/movimento_20261109/walk.png\" id=\"2\"]\n"
	for index in range(8):
		resource += "\n[sub_resource type=\"AtlasTexture\" id=\"Idle%d\"]\natlas = ExtResource(\"1\")\nregion = Rect2(%d, 0, 83, 216)\n"%[index,index*83]
	for index in range(COUNT):
		resource += "\n[sub_resource type=\"AtlasTexture\" id=\"Walk%d\"]\natlas = ExtResource(\"2\")\nregion = Rect2(%d, 0, %d, 216)\n"%[index,index*width,width]
	resource += "\n[resource]\nanimations = [{\n\"name\": &\"idle\", \"loop\": true, \"speed\": 10.0, \"frames\": ["
	for index in range(8):
		resource += "{\"duration\": 1.0, \"texture\": SubResource(\"Idle%d\")}"%index+("," if index<7 else "")
	resource += "]\n}, {\n\"name\": &\"walk\", \"loop\": true, \"speed\": 12.0, \"frames\": ["
	for index in range(COUNT):
		resource += "{\"duration\": 1.0, \"texture\": SubResource(\"Walk%d\")}"%index+("," if index<COUNT-1 else "")
	resource += "]\n}]\n"
	file = FileAccess.open(OUTPUT+"/sprite_frames.tres",FileAccess.WRITE)
	file.store_string(resource)
	file.close()
	print("WALK IMPORT: ",JSON.stringify(manifest))
	quit()

func clear_background(frame: Image) -> void:
	var width := frame.get_width()
	var height := frame.get_height()
	var visited := PackedByteArray()
	visited.resize(width*height)
	var queue: Array[int] = []
	for column in range(width):
		enqueue(frame,column,visited,queue)
		enqueue(frame,(height-1)*width+column,visited,queue)
	for row in range(height):
		enqueue(frame,row*width,visited,queue)
		enqueue(frame,row*width+width-1,visited,queue)
	var head := 0
	while head<queue.size():
		var index := queue[head]
		head += 1
		var column := index%width
		var row := index/width
		frame.set_pixel(column,row,Color(0,0,0,0))
		if column>0:enqueue(frame,index-1,visited,queue)
		if column<width-1:enqueue(frame,index+1,visited,queue)
		if row>0:enqueue(frame,index-width,visited,queue)
		if row<height-1:enqueue(frame,index+width,visited,queue)

func enqueue(frame: Image, index: int, visited: PackedByteArray, queue: Array[int]) -> void:
	if visited[index]!=0:return
	visited[index] = 1
	var pixel := frame.get_pixel(index%frame.get_width(),index/frame.get_width())
	if minf(pixel.r,minf(pixel.g,pixel.b))>0.88 and maxf(pixel.r,maxf(pixel.g,pixel.b))-minf(pixel.r,minf(pixel.g,pixel.b))<0.08:
		queue.append(index)
