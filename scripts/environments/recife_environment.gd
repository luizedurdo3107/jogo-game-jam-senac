extends Node3D

const STONE := Color("555465")
const TEAL := Color("46bfc9")
const GOLD := Color("dfa452")
var batches: Dictionary = {}
var materials: Dictionary = {}
var platforms: Array[StaticBody3D] = []
var ladders: Array[Dictionary] = []
var gate: StaticBody3D
var gate_visual: Node3D
var water: MeshInstance3D
var plants: Array[Node3D] = []
var circuit: Node3D
var reduced := true
var elapsed := 0.0
var gate_animation: AnimationPlayer

func _ready() -> void:
	_build_world()
	_flush_batches()

func material(color: Color, glow := false) -> StandardMaterial3D:
	var key := color.to_html() + str(glow)
	if materials.has(key):
		return materials[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.86
	if glow:
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		result.emission_enabled = true
		result.emission = color
	materials[key] = result
	return result

func box(center: Vector3, dimensions: Vector3, color: Color, glow := false, rotation := Vector3.ZERO) -> void:
	var key := color.to_html() + str(glow)
	if not batches.has(key):
		batches[key] = {"material":material(color, glow), "transforms":[]}
	var orientation := Basis.from_euler(rotation)
	orientation.x *= dimensions.x
	orientation.y *= dimensions.y
	orientation.z *= dimensions.z
	batches[key].transforms.append(Transform3D(orientation, center))

func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = material(color, glow)
	instance.position = at
	parent.add_child(instance)
	return instance

func solid(at: Vector3, dimensions: Vector3, parent: Node3D = self) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.set_meta("audio_surface","metal")
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 2
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	platforms.append(body)
	return body

func floor_piece(left: float, right: float, top: float, depth := 4.0) -> void:
	var dimensions := Vector3(right - left, 0.38, depth)
	var center := Vector3((left + right) * 0.5, top - 0.19, -0.8)
	box(center, dimensions, STONE)
	box(center + Vector3(0, 0.17, 0), Vector3(dimensions.x, 0.05, depth + 0.04), Color("8e847a"))
	solid(center, dimensions).set_meta("audio_surface","metal" if top>0 else ("wet" if top==0 else "concrete"))
	for position_x in range(ceili(left * 2), floori(right * 2)):
		box(Vector3(position_x * 0.5, top + 0.008, -0.8), Vector3(0.018, 0.012, depth), Color("373e4e"))

func add_ladder(position_x: float, bottom: float, top: float) -> void:
	var ladder_data := {"x":position_x,"bottom":bottom,"top":top}
	if is_equal_approx(position_x,13.3) or is_equal_approx(position_x,24.5):
		ladder_data.exit_x = position_x + 0.85
	ladders.append(ladder_data)
	for offset in [-0.3, 0.3]:
		box(Vector3(position_x + offset, (top + bottom) * 0.5, 0.15), Vector3(0.065, top - bottom + 0.3, 0.08), GOLD)
	for rung in range(ceili((top - bottom) / 0.28) + 1):
		box(Vector3(position_x, bottom + rung * 0.28, 0.18), Vector3(0.68, 0.045, 0.1), GOLD)

func sign_text(text: String, at: Vector3, size := 28, color := TEAL) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.pixel_size = 0.009
	label.modulate = color
	label.no_depth_test = false
	label.outline_size = 4
	add_child(label)
	return label

func _building(position_x: float, width: float, height: float, color: Color, roof := false) -> void:
	var front := -4.5
	box(Vector3(position_x, height * 0.5, front - 1.5), Vector3(width, height, 3.0), color)
	for top in [0.2, 3.1, height - 0.2, height + 0.08]:
		box(Vector3(position_x, top, front + 0.15), Vector3(width + 0.22, 0.17, 0.5), Color("b4a58c"))
	for edge in [-width * 0.5 + 0.16, width * 0.5 - 0.16]:
		box(Vector3(position_x + edge, height * 0.5, front + 0.05), Vector3(0.22, height, 0.22), Color("aaa08e"))
	for row in range(2):
		for column in range(3):
			var window_at := Vector3(position_x + (column - 1) * width * 0.28, 1.55 + row * 3.0, front + 0.18)
			box(window_at, Vector3(width * 0.18 + 0.16, 1.85, 0.2), Color("beb095"))
			box(window_at + Vector3(0, -0.05, 0.12), Vector3(width * 0.18, 1.62, 0.06), Color("162d3d"))
			box(window_at + Vector3(0, -0.02, 0.17), Vector3(0.035, 1.62, 0.06), Color("b49b78"))
			box(window_at + Vector3(0, 0.25, 0.18), Vector3(width * 0.18, 0.035, 0.06), GOLD)
			for arc_index in range(9):
				var angle := arc_index * PI / 8
				box(window_at+Vector3(cos(angle)*width*0.095,0.9+sin(angle)*0.27,0.08),Vector3(0.19,0.09,0.12),Color("b5a184"),false,Vector3(0,0,angle+PI*0.5))
			if row == 1:
				box(window_at + Vector3(0, -1.0, 0.35), Vector3(width * 0.22, 0.13, 0.85), STONE)
				for rail in range(6):
					box(window_at + Vector3((rail - 2.5) * width * 0.036, -0.65, 0.75), Vector3(0.035, 0.65, 0.035), Color("292b3b"))
				box(window_at + Vector3(0, -0.3, 0.75), Vector3(width * 0.23, 0.04, 0.06), GOLD)
	if roof:
		for dome_x in [-width * 0.32, width * 0.32]:
			var dome := SphereMesh.new()
			dome.radius = 0.85
			dome.height = 1.6
			dome.radial_segments = 16
			dome.rings = 8
			mesh(self, dome, Vector3(position_x + dome_x, height + 0.55, front - 0.9), Color("304154"))
			box(Vector3(position_x + dome_x, height + 1.35, front - 0.9), Vector3(0.07, 0.5, 0.07), GOLD)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("212740")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a6a0c7")
	settings.ambient_light_energy = 0.38
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("efbe85")
	sun.light_energy = 0.75
	sun.shadow_enabled = false
	add_child(sun)
	var plate := QuadMesh.new()
	plate.size = Vector2(70, 35)
	var far_art := MeshInstance3D.new()
	far_art.mesh = plate
	far_art.position = Vector3(18, 5.0, -23)
	var art_material := StandardMaterial3D.new()
	art_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	art_material.albedo_texture = preload("res://assets/referencias/recife_aprovado.png")
	art_material.uv1_scale = Vector3(0.5,0.5,1)
	art_material.uv1_offset = Vector3(0.5,0,0)
	far_art.material_override = art_material
	add_child(far_art)
	var river := PlaneMesh.new()
	river.size = Vector2(65, 34)
	water = mesh(self, river, Vector3(17, -3.25, -12), Color("18394d"))
	var random := RandomNumberGenerator.new()
	random.seed = 2187
	for reflection in range(65):
		box(Vector3(random.randf_range(-8, 50), -3.23, random.randf_range(-26, 4)), Vector3(random.randf_range(0.15, 1.1), 0.014, 0.06), TEAL.darkened(random.randf_range(0.1, 0.6)), true)
	for pier in range(9):
		box(Vector3(pier * 5.0 - 3, -1.7, -2.4), Vector3(0.65, 3.1, 0.5), Color("3b3f4d"))
	floor_piece(-4, 12.8, 0)
	floor_piece(12.8,13.8,0)
	floor_piece(13.8, 22.65, 0)
	floor_piece(23.75, 24, 0)
	floor_piece(24,25,0)
	floor_piece(25, 40, 0)
	floor_piece(10, 26, -2.7)
	floor_piece(9.8, 21.5, 2.6, 2.0)
	floor_piece(21.5,22.65,2.6,2.0)
	floor_piece(23.75,24.2,2.6,2.0)
	add_ladder(11, 0, 2.6)
	add_ladder(13.3, -2.7, 0)
	add_ladder(24.5, -2.7, 0)
	add_ladder(21, 0, 2.6)
	solid(Vector3(-3.2, 3, 0), Vector3(0.3, 10, 4))
	solid(Vector3(38.5, 3, 0), Vector3(0.3, 10, 4))
	_building(1.0, 4.6, 7.4, Color("37626c"))
	_building(6.0, 4.8, 8.0, Color("915666"))
	_building(12.1, 6.8, 7.1, Color("8c743f"), true)
	_building(20.8, 3.4, 8.4, Color("51485f"))
	_building(28.0, 4.8, 6.6, Color("375b69"))
	_building(35.0, 5.8, 8.0, Color("79634c"))
	box(Vector3(18,-1.65,-2.6),Vector3(18,2.0,0.25),Color("1f3440"))
	box(Vector3(18,-2.5,-3.0),Vector3(18,0.3,1.6),Color("46505a"))
	for position_x in [12.5,18.0,25.5]:
		box(Vector3(position_x,-1.5,-2.35),Vector3(0.15,2,0.18),Color("c18051"))
	box(Vector3(19,-1.8,-2.3),Vector3(14,0.18,0.18),Color("976c4c"))
	for position_x in [9.3,25.2,35.0]:
		box(Vector3(position_x,0.16,1.6),Vector3(0.8,0.32,0.5),Color("454252"))
		for leaf_index in range(5):
			box(Vector3(position_x+(leaf_index-2)*0.12,0.48,1.6),Vector3(0.12,0.65,0.12),Color("45665b"),false,Vector3(0,0,(leaf_index-2)*0.28))
	for position_x in [4.5,16.5,30.5]:
		for chip in range(15):
			box(Vector3(position_x+random.randf_range(-1.7,1.7),random.randf_range(0.3,4.8),-4.25),Vector3(random.randf_range(0.06,0.22),0.035,0.03),Color("464553"))
	for position_x in [6.5,27.5]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(position_x,2,-1.7)
		lamp.light_color = GOLD
		lamp.light_energy = 1.4
		lamp.omni_range = 4.5
		lamp.shadow_enabled = false
		add_child(lamp)
	for position_x in [1.0, 6.0, 19.6, 35.0]:
		box(Vector3(position_x + 1.5, 5, -3.9), Vector3(0.075, 5.5, 0.1), TEAL, true)
	for post in range(21):
		var position_x := post * 2.0 - 3
		box(Vector3(position_x, 0.45, -2.3), Vector3(0.12, 0.9, 0.12), Color("41414c"))
		box(Vector3(position_x, 1.0, -2.3), Vector3(0.22, 0.22, 0.22), GOLD, true)
	box(Vector3(17, 0.62, -2.3), Vector3(40, 0.05, 0.06), STONE)
	for position_x in [9.8, 15.6, 21.5]:
		box(Vector3(position_x, 1.2, -0.9), Vector3(0.11, 2.8, 0.12), Color("4c5365"))
	for post in range(23):
		box(Vector3(10 + post * 0.5, 3.0, -1.9), Vector3(0.045, 0.8, 0.045), GOLD)
	box(Vector3(15.65, 3.4, -1.9), Vector3(11.6, 0.05, 0.05), GOLD)
	box(Vector3(7, 2.5, -3.1), Vector3(4.0, 0.12, 2.4), Color("7b4e57"))
	box(Vector3(7, 0.8, -2.5), Vector3(2.4, 0.65, 0.75), Color("644c3f"))
	sign_text("RECIFE ANTIGO\n2187", Vector3(0.5, 4.5, -4.1), 37, Color("e7dcc5"))
	sign_text("NEXUS\nO AMANHÃ É NOSSO", Vector3(19.2, 6.2, -4.15), 30, Color("d997d9"))
	sign_text("CAPIBARIBE / SETOR 04", Vector3(28.0, 4.0, -3.9), 24, GOLD)
	var plaza := CylinderMesh.new()
	plaza.top_radius = 2.4
	plaza.bottom_radius = 2.4
	plaza.height = 0.03
	plaza.radial_segments = 32
	mesh(self, plaza, Vector3(5.2, 0.025, -0.8), Color("c3ab84"))
	for spoke in range(12):
		var stone := BoxMesh.new()
		stone.size = Vector3(0.06, 0.025, 4.7)
		var pattern := mesh(self, stone, Vector3(5.2, 0.05, -0.8), Color("5d515c"))
		pattern.rotation.y = spoke * PI / 12
	gate_visual = Node3D.new()
	gate_visual.name = "GatePanel"
	gate_visual.position = Vector3(28, 0, 0)
	add_child(gate_visual)
	gate = solid(Vector3(28, 1.65, 0), Vector3(0.45, 3.3, 2.8))
	var gate_mesh := BoxMesh.new()
	gate_mesh.size = Vector3(0.45, 3.3, 2.8)
	mesh(gate_visual, gate_mesh, Vector3(0, 1.65, 0), Color("665561"))
	for stripe in range(5):
		var strip := BoxMesh.new()
		strip.size = Vector3(0.48, 0.1, 2.9)
		mesh(gate_visual, strip, Vector3(0, stripe * 0.65 + 0.2, 0), GOLD, true)
	gate_animation = AnimationPlayer.new()
	add_child(gate_animation)
	var opening := Animation.new()
	opening.length = 1.2
	var track := opening.add_track(Animation.TYPE_VALUE)
	opening.track_set_path(track,NodePath("GatePanel:position"))
	opening.track_insert_key(track,0.0,Vector3(28,0,0))
	opening.track_insert_key(track,1.2,Vector3(28,3.6,0))
	var library := AnimationLibrary.new()
	library.add_animation("open_gate",opening)
	gate_animation.add_animation_library("",library)
	box(Vector3(28, 3.55, 0), Vector3(1.0, 0.35, 3.4), Color("313345"))
	box(Vector3(28, 1.65, -1.8), Vector3(0.7, 3.3, 0.5), Color("313345"))
	sign_text("COMPORTA 04", Vector3(28, 3.9, 1.8), 22, GOLD)
	circuit = Node3D.new()
	circuit.visible = false
	add_child(circuit)
	for segment in [[Vector3(12.8, 2.8, -0.5),Vector3(4,0.055,0.055)],[Vector3(17,1.3,-0.5),Vector3(0.055,3,0.055)],[Vector3(20.5,0.2,-0.5),Vector3(7,0.055,0.055)],[Vector3(25,1,-0.5),Vector3(0.055,1.6,0.055)]]:
		var shape := BoxMesh.new()
		shape.size = segment[1]
		mesh(circuit, shape, segment[0], TEAL, true)
	for position_x in [4, 8, 30, 33]:
		var plant := Node3D.new()
		plant.position = Vector3(position_x, 0, -1.4)
		plant.scale = Vector3.ONE * 0.35
		add_child(plant)
		plants.append(plant)
		for leaf_index in range(4):
			var leaf := PrismMesh.new()
			leaf.size = Vector3(0.45, 1.2, 0.1)
			var leaf_mesh := mesh(plant, leaf, Vector3((leaf_index - 1.5) * 0.15, 0.55, 0), Color("527b61"))
			leaf_mesh.rotation.z = (leaf_index - 1.5) * 0.38

func _flush_batches() -> void:
	for batch in batches.values():
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = BoxMesh.new()
		multimesh.mesh.size = Vector3.ONE
		multimesh.instance_count = batch.transforms.size()
		for index in range(batch.transforms.size()):
			multimesh.set_instance_transform(index, batch.transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = batch.material
		add_child(instance)
	batches.clear()

func set_gaia(active: bool) -> void:
	circuit.visible = active

func open_gate() -> void:
	gate.collision_layer = 0
	gate_animation.play("open_gate")

func show_decision(restore: bool) -> void:
	water.material_override = material(Color("246175") if restore else Color("342c4b"))
	for plant in plants:
		create_tween().tween_property(plant, "scale", Vector3.ONE if restore else Vector3.ONE * 0.2, 1.4)
