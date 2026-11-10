extends "res://scripts/environments/story_environment.gd"

var traffic: Array[Node3D] = []
var armory_door: Node3D
var armory_light: MeshInstance3D
var weapon_display: Node3D
var armory_unlocked := false

func _build_world() -> void:
	var atmosphere := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("0b1024")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("91a8c4")
	settings.ambient_light_energy = 0.72
	atmosphere.environment = settings
	add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-30,0)
	sun.light_color = Color("c0d6f2")
	sun.light_energy = 0.85
	add_child(sun)
	var skyline := Sprite3D.new()
	skyline.name = "SkylineNovaEden"
	skyline.texture = preload("res://assets/processados/nova_eden_rc4/cidade_domo.png")
	skyline.pixel_size = 0.028
	skyline.position = Vector3(18,-1,-18)
	add_child(skyline)
	floor_piece(-2,38,0,6)
	box(Vector3(18,0.026,-0.8),Vector3(40,0.02,6),Color("24384a"))
	for tile in range(20):
		box(Vector3(tile*2,0.039,-0.8),Vector3(0.025,0.005,6),Color("425469"))
		box(Vector3(tile*2+0.6,0.04,1.3),Vector3(0.7,0.007,0.045),Color("34858b") if tile%2==0 else Color("6c426e"),true)
	solid(Vector3(-1,3,0),Vector3(0.4,12,4))
	solid(Vector3(37,3,0),Vector3(0.4,12,4))
	box(Vector3(18,-0.65,1.5),Vector3(40,0.9,0.7),Color("142136"))
	box(Vector3(18,-0.18,1.87),Vector3(40,0.035,0.07),TEAL,true)
	box(Vector3(18,0.02,-1.4),Vector3(40,0.018,0.07),Color("5a7e97"))
	for tile in range(38):
		box(Vector3(tile,0.055,0.6),Vector3(0.55,0.012,0.035),Color("b89c64"),true)
	for position_x in [0.0,34.0]:_facade(position_x)
	for position_x in [9.5,32.5]:_purifier(position_x)
	for position_x in [2.5,15.5,25.5,35.5]:_street_lamp(position_x)
	box(Vector3(17,-0.15,-5),Vector3(42,0.6,2.4),Color("293854"))
	box(Vector3(17,0.18,-3.8),Vector3(42,0.06,0.12),Color("cc599e"),true)
	_sign("NOVA ÉDEN",Vector3(0,4.8,-3.9),Vector2(5.5,0.9),Color("162d46"),TEAL,42)
	_sign("OXIGÊNIO É CIDADANIA",Vector3(0,4.0,-3.8),Vector2(5.5,0.6),Color("111b31"),Color("c4d8e8"),20)
	_sign("SETOR 01 / SAÍDA RESTRITA",Vector3(27.5,4.8,-2.4),Vector2(6.3,0.85),Color("301e31"),Color("ffc28b"),25)
	_make_armory()
	_sign("LYRA / RÁDIO [E]",Vector3(3.8,1.7,-1.9),Vector2(2.1,0.5),Color("172c42"),TEAL,22)
	_make_story_gate()
	for position_x in [27.3,28.7]:
		box(Vector3(position_x,1.8,-1.7),Vector3(0.35,3.6,0.5),Color("243a50"))
		box(Vector3(position_x,1.8,-1.38),Vector3(0.08,3.2,0.06),Color("ec617c"),true)
	circuit = Node3D.new()
	add_child(circuit)
	circuit.hide()
	for index in range(3):
		var vehicle := Node3D.new()
		vehicle.position = Vector3(index*16,7.4+index*1.7,-12-index*3)
		add_child(vehicle)
		traffic.append(vehicle)
		var hull := PrismMesh.new()
		hull.size = Vector3(2.6,0.45,0.85)
		mesh(vehicle,hull,Vector3.ZERO,Color("33445d"))
		var glass := BoxMesh.new()
		glass.size = Vector3(1.1,0.18,0.65)
		mesh(vehicle,glass,Vector3(0,0.2,0),TEAL,true)
		var engine := BoxMesh.new()
		engine.size = Vector3(0.16,0.12,0.7)
		mesh(vehicle,engine,Vector3(-1.2,0,0),Color("ed7bc5"),true)

func _facade(position_x: float) -> void:
	box(Vector3(position_x,1.8,-6),Vector3(6.0,3.6,3.2),Color("1a263d"))
	box(Vector3(position_x,1.8,-4.32),Vector3(5.5,3.2,0.1),Color("263c54"))
	for edge in [-2.8,2.8]:
		box(Vector3(position_x+edge,1.8,-4),Vector3(0.24,3.6,0.65),Color("77849a"))
		box(Vector3(position_x+edge-0.2,1.8,-3.64),Vector3(0.055,3.5,0.05),TEAL,true)
	for row in range(1):
		var height := 2.4+row*2.0
		box(Vector3(position_x,height,-4),Vector3(5.5,1.1,0.25),Color("101c30"))
		box(Vector3(position_x,height-0.6,-3.65),Vector3(6.0,0.12,0.9),Color("52647b"))
		for column in range(5):
			box(Vector3(position_x-2.4+column*1.2,height,-3.82),Vector3(0.045,1.1,0.05),Color("6e8797"))
			if (column+row)%3==0:box(Vector3(position_x-2.7+column*1.2,height,-3.78),Vector3(0.35,0.045,0.04),Color("d7aa72"),true)
	box(Vector3(position_x,0.9,-3.4),Vector3(4.8,1.8,0.6),Color("1d2b3e"))
	for vent in range(9):box(Vector3(position_x-2+vent*0.5,0.9,-3.05),Vector3(0.25,1.25,0.06),Color("344a5c"))

func _purifier(position_x: float) -> void:
	for offset in [-0.35,0.35]:
		var tube := CylinderMesh.new()
		tube.top_radius = 0.26
		tube.bottom_radius = 0.3
		tube.height = 3.6
		tube.radial_segments = 12
		mesh(self,tube,Vector3(position_x+offset,1.9,-3.1),Color("395b69"))
		for height in [0.3,1.8,3.6]:box(Vector3(position_x+offset,height,-2.78),Vector3(0.48,0.08,0.08),TEAL,true)
	_sign("O₂ / 98%",Vector3(position_x,4.2,-3),Vector2(1.8,0.55),Color("112c36"),TEAL,24)

func _street_lamp(position_x: float) -> void:
	box(Vector3(position_x,1.7,-2.1),Vector3(0.1,3.4,0.12),Color("7d8999"))
	box(Vector3(position_x+0.25,3.4,-1.95),Vector3(0.7,0.12,0.6),Color("263c54"))
	box(Vector3(position_x+0.25,3.32,-1.9),Vector3(0.48,0.055,0.35),Color("ffd59c"),true)
	var light := OmniLight3D.new()
	light.position = Vector3(position_x,2.8,-1.5)
	light.light_color = Color("ffbf8a")
	light.light_energy = 0.7
	light.omni_range = 4
	add_child(light)

func _sign(text: String, point: Vector3, dimensions: Vector2, plate_color: Color, ink: Color, font_size: int) -> void:
	box(point,Vector3(dimensions.x,dimensions.y,0.12),plate_color)
	box(point+Vector3(0,-dimensions.y*0.5,0.09),Vector3(dimensions.x,0.045,0.04),ink,true)
	sign_text(text,point+Vector3(0,0,0.1),font_size,ink)

func _make_armory() -> void:
	box(Vector3(6.5,1.4,-1.7),Vector3(2.5,2.8,0.65),Color("516078"))
	box(Vector3(6.5,1.4,-1.3),Vector3(2.15,2.45,0.1),Color("0d1c2d"))
	armory_door = Node3D.new()
	armory_door.position = Vector3(6.5,0,-1.18)
	add_child(armory_door)
	var panel := BoxMesh.new()
	panel.size = Vector3(2.1,2.35,0.13)
	mesh(armory_door,panel,Vector3(0,1.4,0),Color("293d54"))
	for offset in [-0.8,0.8]:
		var strip := BoxMesh.new()
		strip.size = Vector3(0.055,2.05,0.06)
		mesh(armory_door,strip,Vector3(offset,1.4,0.09),TEAL,true)
	var indicator := BoxMesh.new()
	indicator.size = Vector3(0.5,0.08,0.06)
	armory_light = mesh(self,indicator,Vector3(6.5,2.95,-1.1),Color("ed6d87"),true)
	_sign("ARSENAL / PULSO",Vector3(6.5,3.4,-1.5),Vector2(3.2,0.6),Color("1c2c40"),TEAL,27)
	weapon_display = make_baton(self,Vector3(6.5,1.45,-1.25))
	weapon_display.rotation.z = -0.55

func make_baton(parent: Node3D, point: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = point
	parent.add_child(root)
	var handle := CylinderMesh.new()
	handle.top_radius = 0.055
	handle.bottom_radius = 0.065
	handle.height = 0.4
	mesh(root,handle,Vector3.ZERO,Color("344052"))
	var blade := CylinderMesh.new()
	blade.top_radius = 0.045
	blade.bottom_radius = 0.075
	blade.height = 0.67
	mesh(root,blade,Vector3(0,0.48,0),TEAL,true)
	return root

func sync_armory(opened: bool, collected: bool) -> void:
	if opened and not armory_unlocked:
		armory_unlocked = true
		create_tween().tween_property(armory_door,"position:y",2.6,0.65)
	armory_light.material_override = material(TEAL if opened else Color("ed6d87"),true)
	weapon_display.visible = not collected

func _process(delta: float) -> void:
	if GameState.input_locked:return
	for index in range(traffic.size()):
		traffic[index].position.x += delta*(1.8+index*0.7)
		if traffic[index].position.x>46:traffic[index].position.x = -12
