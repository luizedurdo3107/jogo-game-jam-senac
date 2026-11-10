extends Node3D

signal changed(active: bool)

var active := false
var digital_root: Node3D
var physical_materials: Array[Dictionary] = []
var digital_materials: Dictionary = {}
var mode_nodes: Array[Dictionary] = []
var lights: Array[Dictionary] = []
var paths: Array[Dictionary] = []
var scan: MeshInstance3D
var memory: Node3D
var elapsed := 0.0
var extent := Vector2(32,9)
var physical_audio: AudioStreamPlayer:
	get:return AudioDirector.physical_players[AudioDirector.physical_index]
var digital_audio: AudioStreamPlayer:
	get:return AudioDirector.digital_player
var muted := false

func _ready() -> void:
	digital_root = Node3D.new()
	digital_root.name = "DigitalStructure"
	digital_root.visible = false
	add_child(digital_root)
	var line_material := glow(Color("367d8b"))
	for position_x in range(-2,ceili(extent.x)+2,2):
		_segment(digital_root,Vector3(position_x,-3,-1.0),Vector3(position_x,extent.y,-1.0),0.012,line_material)
	for position_y in range(-3,ceili(extent.y)+1):
		_segment(digital_root,Vector3(-2,position_y,-1.0),Vector3(extent.x,position_y,-1.0),0.012,line_material)
	var plane := BoxMesh.new()
	plane.size = Vector3(0.025,extent.y+3,0.035)
	scan = MeshInstance3D.new()
	scan.mesh = plane
	scan.material_override = glow(Color("9be3ca"))
	scan.position = Vector3(0,(extent.y-3)*0.5,0.8)
	digital_root.add_child(scan)
	memory = Node3D.new()
	memory.name = "HistoricalRecord"
	memory.visible = false
	digital_root.add_child(memory)
	_update_audio()

func glow(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.albedo_color = color
	result.emission_enabled = true
	result.emission = color
	return result

func register_physical(node: Node) -> void:
	if node is MeshInstance3D or node is MultiMeshInstance3D:
		var original: Material = node.material_override
		if original is StandardMaterial3D:
			var identity := original.get_instance_id()
			if not digital_materials.has(identity):
				var alternate: StandardMaterial3D = original.duplicate()
				alternate.albedo_color = original.albedo_color.lerp(Color("0e2233"),0.83)
				alternate.albedo_color.a = original.albedo_color.a
				alternate.emission_enabled = false
				alternate.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				digital_materials[identity] = alternate
			physical_materials.append({"node":node,"physical":original,"digital":digital_materials[identity]})
	elif node is Light3D:
		lights.append({"node":node,"energy":node.light_energy})
	for child in node.get_children():
		register_physical(child)

func register_mode(node: Node3D, mode: String) -> void:
	mode_nodes.append({"node":node,"mode":mode})
	node.visible = (mode=="gaia")==active

func set_active(enabled: bool) -> void:
	active = enabled
	GameState.gaia_active = enabled
	digital_root.visible = enabled
	for record in physical_materials:
		if is_instance_valid(record.node):
			record.node.material_override = record.digital if enabled else record.physical
	for record in mode_nodes:
		if is_instance_valid(record.node):
			record.node.visible = (record.mode=="gaia")==enabled
	for record in lights:
		if is_instance_valid(record.node):
			record.node.light_energy = record.energy*(0.45 if enabled else 1.0)
	_update_audio()
	changed.emit(enabled)

func allows(mode: String) -> bool:
	return mode=="both" or (mode=="gaia")==active

func blocked_feedback(mode: String) -> String:
	return "[CORPO NECESSÁRIO] GAIA não transporta módulos, não conversa com moradores e não move mecanismos." if mode=="physical" else "[ACESSO DIGITAL] Alterne para GAIA para selecionar conexões e comandos remotos."

func add_outline(at: Vector3, dimensions: Vector3, fault := false) -> void:
	var paint := glow(Color("e9b464") if fault else Color("6ed9d1"))
	var center := at+Vector3(0,dimensions.y*0.5,0)
	var half := dimensions*0.5
	for side_x in [-1,1]:
		for side_z in [-1,1]:
			_segment(digital_root,center+Vector3(side_x*half.x,-half.y,side_z*half.z),center+Vector3(side_x*half.x,half.y,side_z*half.z),0.018,paint)
	for side_y in [-1,1]:
		for side_z in [-1,1]:
			_segment(digital_root,center+Vector3(-half.x,side_y*half.y,side_z*half.z),center+Vector3(half.x,side_y*half.y,side_z*half.z),0.018,paint)
		for side_x in [-1,1]:
			_segment(digital_root,center+Vector3(side_x*half.x,side_y*half.y,-half.z),center+Vector3(side_x*half.x,side_y*half.y,half.z),0.018,paint)

func _segment(parent: Node3D, start: Vector3, finish: Vector3, thickness: float, paint: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(thickness,thickness,maxf(0.001,start.distance_to(finish)))
	mesh.mesh = shape
	mesh.material_override = paint
	mesh.position = (start+finish)*0.5
	parent.add_child(mesh)
	if not start.is_equal_approx(finish):
		mesh.look_at_from_position(mesh.position,finish,Vector3.RIGHT if absf((finish-start).normalized().y)>0.95 else Vector3.UP)
	return mesh

func add_path(points: Array, color := Color("51d5dc")) -> int:
	if points.size()<2:return -1
	var paint := glow(color)
	for index in range(points.size()-1):
		_segment(digital_root,points[index],points[index+1],0.035,paint)
	var pulse := MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.085
	orb.height = 0.17
	orb.radial_segments = 8
	orb.rings = 4
	pulse.mesh = orb
	pulse.material_override = glow(Color("e4fbd9"))
	digital_root.add_child(pulse)
	paths.append({"points":points,"pulse":pulse,"paint":paint,"color":color})
	return paths.size()-1

func set_path_enabled(index: int, enabled: bool) -> void:
	if index<0 or index>=paths.size():return
	var record: Dictionary = paths[index]
	record.pulse.visible = enabled
	var color: Color = record.color if enabled else record.color.darkened(0.65)
	record.paint.albedo_color = color
	record.paint.emission = color

func add_data(text: String, at: Vector3, color := Color("8fe1cc")) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 26
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 5
	digital_root.add_child(label)
	return label

func show_memory(kind: String, at: Vector3) -> void:
	for child in memory.get_children():
		memory.remove_child(child)
		child.queue_free()
	memory.position = at+Vector3(0,1.8,-0.7)
	memory.visible = true
	var title := Label3D.new()
	var timeline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/timeline.json"))
	title.text = "PASSADO / %s\nARQUIVO · NÃO É VIAGEM NO TEMPO"%str(timeline.records.get(kind,"Memória do Recife"))
	title.font_size = 24
	title.pixel_size = 0.008
	title.position.y = 1.7
	title.modulate = Color("f1dca7")
	memory.add_child(title)
	for index in range(5):
		var ghost := MeshInstance3D.new()
		if kind=="soil":
			var leaf := PrismMesh.new()
			leaf.size = Vector3(0.6,1.2+index*0.1,0.4)
			ghost.mesh = leaf
		elif kind=="air":
			var duct := CylinderMesh.new()
			duct.top_radius = 0.35
			duct.bottom_radius = 0.35
			duct.height = 1.3
			duct.radial_segments = 12
			ghost.mesh = duct
		else:
			var building := BoxMesh.new()
			building.size = Vector3(0.55,0.6+(index%3)*0.3,0.5)
			ghost.mesh = building
		ghost.material_override = glow(Color("6fbfae"))
		ghost.position = Vector3((index-2)*0.7,0.4,0)
		memory.add_child(ghost)

func _update_audio() -> void:
	AudioDirector.set_gaia(active)

func set_muted(enabled: bool) -> void:
	muted = enabled
	AudioDirector.set_muted(enabled)

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	scan.position.x = fposmod(elapsed*3.5,extent.x+2)-1
	for record in paths:
		var points: Array = record.points
		var location := fposmod(elapsed*1.4,points.size()-1)
		var index := int(location)
		record.pulse.position = points[index].lerp(points[index+1],location-index)
