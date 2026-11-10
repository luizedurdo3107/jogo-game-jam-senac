extends Node3D

var exhausts: Array[MeshInstance3D] = []
var landing_gear: Node3D
var flying := false
var elapsed := 0.0

func _ready() -> void:
	name = "ARCA01"
	var hull := _loft([
		Vector3(-3.0,0.32,0.42),Vector3(-2.5,0.62,0.72),Vector3(-0.8,0.72,0.84),
		Vector3(1.15,0.57,0.68),Vector3(2.3,0.34,0.46),Vector3(3.1,0.06,0.08)
	])
	_piece(hull,Vector3.ZERO,Color("b3c5ce"),0.65)
	_box(Vector3(-0.6,-0.53,0),Vector3(4.7,0.3,1.15),Color("263d54"))
	var canopy := SphereMesh.new()
	canopy.radius = 0.62
	canopy.height = 1.24
	var glass := _piece(canopy,Vector3(1.3,0.45,0),Color("143b55"),0.65)
	glass.scale = Vector3(1.3,0.55,0.87)
	for side in [-1.0,1.0]:
		var wing := _wedge(PackedVector3Array([
			Vector3(-2.5,-0.1,side*0.45),Vector3(0.65,-0.12,side*0.68),
			Vector3(-1.4,-0.32,side*2.45),Vector3(-2.6,-0.32,side*2.1)
		]),0.12)
		_piece(wing,Vector3.ZERO,Color("3d546c"),0.6)
		_box(Vector3(-1.9,-0.16,side*1.4),Vector3(1.1,0.08,0.16),Color("e6ac65"))
		var pod := CapsuleMesh.new()
		pod.radius = 0.31
		pod.height = 2.9
		var nacelle := _piece(pod,Vector3(-1.65,-0.04,side*1.33),Color("859dad"),0.8)
		nacelle.rotation.z = -PI*0.5
		var nozzle := CylinderMesh.new()
		nozzle.top_radius = 0.24
		nozzle.bottom_radius = 0.36
		nozzle.height = 0.5
		nozzle.radial_segments = 16
		var bell := _piece(nozzle,Vector3(-3.12,-0.04,side*1.33),Color("15263b"),0.75)
		bell.rotation.z = -PI*0.5
		for layer in range(2):
			var plume := CylinderMesh.new()
			plume.top_radius = 0.23 if layer==0 else 0.12
			plume.bottom_radius = 0.015
			plume.height = 1.7 if layer==0 else 1.15
			plume.radial_segments = 16
			var flame := _piece(plume,Vector3(-3.8,-0.04,side*1.33),Color("277fcb") if layer==0 else Color("b7fcff"),0,true)
			flame.rotation.z = -PI*0.5
			exhausts.append(flame)
		var fin := _wedge(PackedVector3Array([
			Vector3(-2.4,0.2,side*0.43),Vector3(-1.0,0.2,side*0.48),
			Vector3(-2.1,1.5,side*0.64),Vector3(-2.65,1.5,side*0.65)
		]),0.09)
		_piece(fin,Vector3.ZERO,Color("334a65"),0.55)
		for index in range(5):
			_box(Vector3(-1.9+index*0.54,0.13,side*0.78),Vector3(0.34,0.18,0.035),Color("8cdeec"),true)
		_box(Vector3(-0.7,-0.14,side*0.79),Vector3(3.1,0.065,0.045),Color("e0a36a"))
		_box(Vector3(2.35,0.08,side*0.37),Vector3(0.37,0.055,0.06),Color("a9f4ff"),true)
		for panel_index in range(4):
			_box(Vector3(-2.0+panel_index*0.8,0.47,side*0.53),Vector3(0.025,0.24,0.15),Color("526a7c"))
	var identity := Label3D.new()
	identity.text = "ARCA-01"
	identity.font_size = 64
	identity.pixel_size = 0.0033
	identity.position = Vector3(0.8,0.05,0.8)
	identity.modulate = Color("e9ddc8")
	identity.outline_size = 0
	add_child(identity)
	landing_gear = Node3D.new()
	add_child(landing_gear)
	for point in [Vector3(-1.7,-0.84,0.6),Vector3(-1.7,-0.84,-0.6),Vector3(1.8,-0.75,0)]:
		var strut := BoxMesh.new()
		strut.size = Vector3(0.13,0.62,0.13)
		_piece(strut,point,Color("8496a5"),0.6, false,landing_gear)
		var foot := BoxMesh.new()
		foot.size = Vector3(0.55,0.13,0.36)
		_piece(foot,point+Vector3(0,-0.34,0),Color("26394c"),0.4,false,landing_gear)
	set_flight(flying)

func set_flight(enabled: bool) -> void:
	flying = enabled
	for exhaust in exhausts:exhaust.visible = flying
	if landing_gear:landing_gear.visible = not flying

func _process(delta: float) -> void:
	elapsed += delta
	if not flying:return
	for index in range(exhausts.size()):
		exhausts[index].scale.y = 0.92+sin(elapsed*23+index)*0.08

func _box(point: Vector3, dimensions: Vector3, color: Color, glow := false) -> void:
	var shape := BoxMesh.new()
	shape.size = dimensions
	_piece(shape,point,color,0.45,glow)

func _piece(shape: Mesh, point: Vector3, color: Color, metallic := 0.0, glow := false, parent: Node3D = self) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.position = point
	var ink := StandardMaterial3D.new()
	ink.albedo_color = color
	ink.metallic = metallic
	ink.roughness = 0.38
	if glow:
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.emission_enabled = true
		ink.emission = color
	instance.material_override = ink
	parent.add_child(instance)
	return instance

func _loft(sections: Array) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section_index in range(sections.size()-1):
		for side_index in range(12):
			var angle := side_index*TAU/12
			var next_angle := (side_index+1)*TAU/12
			var first: Vector3 = sections[section_index]
			var second: Vector3 = sections[section_index+1]
			var points := [Vector3(first.x,cos(angle)*first.y,sin(angle)*first.z),Vector3(second.x,cos(angle)*second.y,sin(angle)*second.z),Vector3(second.x,cos(next_angle)*second.y,sin(next_angle)*second.z),Vector3(first.x,cos(next_angle)*first.y,sin(next_angle)*first.z)]
			for vertex in [0,2,1,0,3,2]:surface.add_vertex(points[vertex])
	surface.generate_normals()
	return surface.commit()

func _wedge(outline: PackedVector3Array, thickness: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for offset in [Vector3(0,thickness*0.5,0),Vector3(0,-thickness*0.5,0)]:
		for point in outline:points.append(point+offset)
	for vertex in [0,1,2,0,2,3,4,6,5,4,7,6,0,4,5,0,5,1,1,5,6,1,6,2,2,6,7,2,7,3,3,7,4,3,4,0]:surface.add_vertex(points[vertex])
	surface.generate_normals()
	var shape := surface.commit()
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shape.surface_set_material(0,material)
	return shape
