extends "res://scripts/environments/recife_environment.gd"

var station_id := "water"
var grit: ImageTexture
var flood: MeshInstance3D
var reservoir: MeshInstance3D
var flood_paint: StandardMaterial3D
var reservoir_paint: StandardMaterial3D
var valve_visuals: Dictionary = {}
var fans: Array[Node3D] = []
var fog_root: Node3D
var young_plants: Array[Node3D] = []
var gate_height := 0.0
var gate_opened := false
var lift_x := 8.0
var lift_stops: Array = [0.0,2.6,5.2,7.8]
var restoration_applied := false
var fog_materials: Array[StandardMaterial3D] = []
var duct_shutters: Array[MeshInstance3D] = []
var plant_target := 0.38
var fan_speed := 0.18
var flood_target := 100.0
var pump_started := false

func material(color: Color, glow := false) -> StandardMaterial3D:
	var result := super.material(color,glow)
	if not glow and grit:
		result.albedo_texture = grit
		result.uv1_triplanar = true
		result.uv1_scale = Vector3.ONE*0.65
		result.roughness = 0.94
	return result

func _build_world() -> void:
	_create_grit()
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("171c35")
	atmosphere.sky_horizon_color = Color("65576d")
	atmosphere.ground_horizon_color = Color("2e344a")
	atmosphere.ground_bottom_color = Color("101d2c")
	sky.sky_material = atmosphere
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("959eb2")
	settings.ambient_light_energy = 0.48
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38,-30,0)
	sun.light_color = Color("bac5dc")
	sun.light_energy = 0.9
	sun.shadow_enabled = false
	add_child(sun)
	fog_root = Node3D.new()
	add_child(fog_root)
	_build_horizon()
	match station_id:
		"water":_waterworks()
		"soil":_greenhouse()
		"air":_atmos()
	_make_gate()
	solid(Vector3(-1,4,0),Vector3(0.4,24,3))
	solid(Vector3(26.2 if station_id=="air" else 34.2,4,0),Vector3(0.4,24,3))

func _create_grit() -> void:
	var image := Image.create(64,64,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 2187
	noise.frequency = 0.17
	for pixel_y in range(64):
		for pixel_x in range(64):
			var intensity := 0.68+(noise.get_noise_2d(pixel_x,pixel_y)+1)*0.16
			if pixel_y%21==0 or pixel_x%31==0:
				intensity *= 0.65
			image.set_pixel(pixel_x,pixel_y,Color(intensity,intensity*0.98,intensity*0.94))
	grit = ImageTexture.create_from_image(image)

func floor_piece(left: float, right: float, top: float, depth := 4.0) -> void:
	var dimensions := Vector3(right-left,0.25,depth)
	var center := Vector3((left+right)*0.5,top-0.125,-0.7)
	box(center,dimensions,Color("495365"))
	box(center+Vector3(0,0.14,0),Vector3(dimensions.x,0.03,depth+0.06),Color("77838c"))
	solid(center,dimensions).set_meta("audio_surface","metal" if top>0 or station_id=="air" else ("wet" if station_id=="water" else "concrete"))
	for post_x in range(ceili(left),floori(right),2):
		box(Vector3(post_x,top+0.45,-2.3),Vector3(0.055,0.9,0.055),Color("aa7c47"))
		box(Vector3(post_x,top+0.9,-2.3),Vector3(1.9,0.055,0.055),GOLD)
		box(Vector3(post_x,top+0.025,-0.6),Vector3(0.04,0.012,depth),Color("303b4a"))

func pipe(start: Vector3, finish: Vector3, radius: float, color: Color, parent: Node3D = self) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = start.distance_to(finish)
	shape.radial_segments = 12
	var instance := mesh(parent,shape,(start+finish)*0.5,color)
	instance.quaternion = Quaternion(Vector3.UP,(finish-start).normalized())
	return instance

func _build_horizon() -> void:
	for index in range(12):
		var height := 4+(index*7)%9
		box(Vector3(index*4-6,height*0.5-1,-21),Vector3(2.7,height,3),Color("29334c"))
		for light_index in range(4):
			box(Vector3(index*4-6,(light_index+1)*1.3,-19.4),Vector3(0.9,0.06,0.04),Color("688d9b"),true)
	var river := PlaneMesh.new()
	river.size = Vector2(70,35)
	mesh(self,river,Vector3(17,-3.7,-13),Color("173346"))
	box(Vector3(14,-0.8,-11),Vector3(38,0.35,2.0),Color("5a5966"))
	for index in range(7):
		var bridge_x := index*5.0-2
		box(Vector3(bridge_x,-2.1,-11),Vector3(0.55,2.5,2.4),Color("5d5b68"))
		for segment in range(8):
			var angle := segment*PI/7
			box(Vector3(bridge_x+2.5+cos(angle)*2.2,-1.1+sin(angle)*0.6,-9.8),Vector3(0.75,0.14,0.2),Color("867b79"),false,Vector3(0,0,angle-PI*0.5))
		box(Vector3(bridge_x,0,-10),Vector3(0.14,0.7,0.14),GOLD,true)

func _waterworks() -> void:
	floor_piece(0,34,0)
	floor_piece(5,10,2.6,2.6)
	floor_piece(20,27,2.6,2.6)
	floor_piece(10,24,-2.7)
	add_ladder(6,0,2.6)
	add_ladder(11,-2.7,0)
	add_ladder(23,-2.7,2.6)
	box(Vector3(18,2.9,-5.8),Vector3(15,7,3),Color("384654"))
	box(Vector3(15,-1.7,-2.7),Vector3(10,2.2,0.45),Color("35424d"))
	for channel in range(3):
		pipe(Vector3(2,3.2+channel*0.65,-2.9),Vector3(14+channel*2,3.2+channel*0.65,-2.9),0.18,Color("775e4d"))
		pipe(Vector3(14+channel*2,3.2+channel*0.65,-2.9),Vector3(14+channel*2,-2.5,-2.9),0.18,Color("775e4d"))
		for brace in range(4):
			box(Vector3(3+brace*3,3.2+channel*0.65,-2.6),Vector3(0.07,0.7,0.08),Color("99948a"))
	for position_x in [12,22]:
		pipe(Vector3(position_x,-2.3,-2),Vector3(position_x,4.8,-2),0.26,Color("81634f"))
	var tank := CylinderMesh.new()
	tank.top_radius = 1.6
	tank.bottom_radius = 1.6
	tank.height = 5.8
	tank.radial_segments = 20
	mesh(self,tank,Vector3(25,3,-4.2),Color("294e60"))
	for tank_y in [0.3,2.6,5.6]:
		var ring := TorusMesh.new()
		ring.inner_radius = 1.5
		ring.outer_radius = 1.7
		ring.rings = 20
		ring.ring_segments = 6
		mesh(self,ring,Vector3(25,tank_y,-4.2),Color("a27b45"))
	var fluid := BoxMesh.new()
	fluid.size = Vector3(8,0.25,2.5)
	flood = mesh(self,fluid,Vector3(15,-0.7,-0.8),Color("4d6559"))
	flood_paint = flood.material_override.duplicate()
	flood.material_override = flood_paint
	var cross_section := BoxMesh.new()
	cross_section.size = Vector3(8,2.0,0.06)
	var chamber_water := mesh(flood,cross_section,Vector3(0,-1.0,1.3),Color("42635f"))
	var water_material: StandardMaterial3D = chamber_water.material_override.duplicate()
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.albedo_color.a = 0.62
	water_material.albedo_texture = null
	chamber_water.material_override = water_material
	var level := BoxMesh.new()
	level.size = Vector3(2.8,1.0,0.1)
	reservoir = mesh(self,level,Vector3(25,1.0,-2.55),Color("4d6b67"))
	reservoir_paint = reservoir.material_override.duplicate()
	reservoir.material_override = reservoir_paint
	for position_x in [18,20]:
		pipe(Vector3(position_x,0.5,-1.1),Vector3(position_x,0.5,-2.4),0.5,Color("42697a"))
	sign_text("CAPIBARIBE\nCASA DE PRESSÃO",Vector3(17,6.3,-4.1),34,TEAL)
	sign_text("A / ESGOTO    B / FILTRO    C / ARCA",Vector3(8,5.8,-3),21,GOLD)

func _greenhouse() -> void:
	floor_piece(0,34,0)
	floor_piece(8,25,2.6,2.8)
	add_ladder(9,0,2.6)
	add_ladder(24,0,2.6)
	box(Vector3(16,0.25,-4.7),Vector3(22,0.5,7),Color("615b48"))
	for depth in [-3.1,-6.5,-9.0]:
		for rib in range(17):
			var angle := rib*PI/16
			var at := Vector3(16+cos(angle)*11,0.5+sin(angle)*8.8,depth)
			box(at,Vector3(1.4,0.09,0.12),Color("758986"),false,Vector3(0,0,angle+PI*0.5))
	var pane := BoxMesh.new()
	pane.size = Vector3(19,6,0.035)
	var glass := mesh(self,pane,Vector3(16,3.8,-3.3),Color("466e68"))
	var glass_material: StandardMaterial3D = glass.material_override.duplicate()
	glass_material.albedo_texture = null
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color.a = 0.13
	glass.material_override = glass_material
	for rib in range(16):
		if rib in [3,4,10,13]:continue
		var angle := (rib+0.5)*PI/16
		var roof_panel := BoxMesh.new()
		roof_panel.size = Vector3(1.9,0.035,5.7)
		var roof := mesh(self,roof_panel,Vector3(16+cos(angle)*10.8,0.5+sin(angle)*8.6,-6.2),Color("587d6a"))
		roof.rotation.z = angle+PI*0.5
		roof.material_override = glass_material
	for index in range(8):
		box(Vector3(7+index*2.4,4.5+(index%3)*0.5,-3.15),Vector3(0.025,1.5,0.03),Color("aab6a7"),false,Vector3(0,0,index*0.51))
	for index in range(4):
		var capsule_x := 10+index*3.4
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.64
		cylinder.bottom_radius = 0.64
		cylinder.height = 2.45
		cylinder.radial_segments = 16
		var capsule := mesh(self,cylinder,Vector3(capsule_x,4.05,-3),Color("264b49") if index in [1,3] else Color("5c504a"))
		var capsule_glass: StandardMaterial3D = capsule.material_override.duplicate()
		capsule_glass.albedo_texture = null
		capsule_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		capsule_glass.albedo_color.a = 0.22
		capsule.material_override = capsule_glass
		box(Vector3(capsule_x,2.82,-3),Vector3(1.5,0.3,1.4),Color("635e4f"))
		box(Vector3(capsule_x,5.3,-3),Vector3(1.5,0.2,1.4),Color("63796c"))
		box(Vector3(capsule_x,4,-2.35),Vector3(0.07,2.3,0.05),Color("91c37d") if index in [1,3] else Color("a17e59"),true)
		sign_text(["A","B","C","D"][index],Vector3(capsule_x,5.7,-2.3),28,GOLD)
		_seedling(Vector3(capsule_x,2.9,-3),1.05,index in [1,3])
	for branch in range(9):
		var start := Vector3(4+branch*2.6,0.15,-1.7)
		pipe(start,start+Vector3(1.3,0.7+(branch%3)*0.25,-0.7),0.12,Color("685141"))
		pipe(start+Vector3(1.3,0.7,-0.7),start+Vector3(1.7,1.6,-1.0),0.065,Color("786548"))
	for position_x in [12.5,19.5]:
		var sprout := _seedling(Vector3(position_x,0.08,-0.9),0.38,true)
		young_plants.append(sprout)
	for position_x in [7,12,22,25]:
		box(Vector3(position_x,6.0,-3.6),Vector3(1.6,0.32,1.0),Color("7e684b"))
		for offset in [-0.4,0.4]:
			_seedling(Vector3(position_x+offset,6.15,-3.6),0.6,true)
			pipe(Vector3(position_x+offset,6.1,-3.6),Vector3(position_x+offset,7.8,-3.6),0.018,Color("5e7970"))
	for position_x in [14,23]:
		pipe(Vector3(position_x,0.25,-1.4),Vector3(position_x,3.0,-1.4),0.09,Color("567b6d"))
	pipe(Vector3(8,0.4,-1.3),Vector3(26,0.4,-1.3),0.1,Color("6e8268"))
	var vault := CylinderMesh.new()
	vault.top_radius = 1.75
	vault.bottom_radius = 1.75
	vault.height = 0.3
	vault.radial_segments = 24
	var safe := mesh(self,vault,Vector3(29.6,1.8,-2.8),Color("747d6e"))
	safe.rotation.x = PI*0.5
	for shelf in range(4):
		box(Vector3(3,0.6+shelf*0.55,-2.3),Vector3(3.8,0.1,0.8),Color("7f775d"))
		for jar in range(5):
			box(Vector3(1.5+jar*0.65,0.8+shelf*0.55,-2.3),Vector3(0.3,0.25,0.3),Color("aa9f68"))
	sign_text("BANCO VERDE\nPRESERVAR NÃO É RECRIAR UMA FLORESTA",Vector3(16,8.8,-5),30,Color("b8ce86"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(18,5,-1.8)
	lamp.light_color = Color("b5d78e")
	lamp.light_energy = 1.0
	lamp.omni_range = 9
	add_child(lamp)

func _seedling(at: Vector3, size: float, viable: bool) -> Node3D:
	var root := Node3D.new()
	root.position = at
	root.scale = Vector3.ONE*size
	add_child(root)
	pipe(Vector3.ZERO,Vector3(0,1,0),0.04,Color("778957"),root)
	for index in range(4):
		var leaf := PrismMesh.new()
		leaf.size = Vector3(0.4,0.85,0.1)
		var blade := mesh(root,leaf,Vector3((index%2-0.5)*0.3,0.4+index*0.15,0),Color("72935b") if viable else Color("83684b"))
		blade.rotation.z = 0.7 if index%2==0 else -0.7
	return root

func _atmos() -> void:
	for height in [0.0,2.6,5.2,7.8]:
		floor_piece(0,7.4,height,3.0)
		floor_piece(8.6,26,height,3.0)
	for ladder_x in [3.5,23.5]:
		add_ladder(ladder_x,0,7.8)
	box(Vector3(18,5.5,-4.5),Vector3(16,12,3.0),Color("414555"))
	for position_x in [11.5,24]:
		pipe(Vector3(position_x,-0.1,-2.5),Vector3(position_x,11.8,-2.5),0.65,Color("6e6259"))
	for height in [1.5,4.1,6.7,9.3]:
		_fan(Vector3(18,height,-2.7),1.0)
		box(Vector3(18,height,-2.85),Vector3(3,2.5,0.25),Color("282f3c"))
		pipe(Vector3(13,height+1,-2.1),Vector3(23,height+1,-2.1),0.14,Color("9b7450"))
		var shutter := BoxMesh.new()
		shutter.size = Vector3(1.25,0.85,0.08)
		duct_shutters.append(mesh(self,shutter,Vector3(14,height,-2.2),Color("626e76")))
	for post in range(5):
		box(Vector3(7.15,post*2.4+1,-0.5),Vector3(0.1,2.4,0.1),Color("b6935a"))
		box(Vector3(8.85,post*2.4+1,-0.5),Vector3(0.1,2.4,0.1),Color("b6935a"))
	for crane_index in range(3):
		var port_x := crane_index*9-8
		box(Vector3(port_x,3,-15),Vector3(0.5,7,0.5),Color("6b5060"))
		box(Vector3(port_x+2.5,5.5,-15),Vector3(7.5,0.35,0.4),Color("875f67"),false,Vector3(0,0,-0.16))
	for index in range(4):
		var fog_shape := QuadMesh.new()
		fog_shape.size = Vector2(27,1.4)
		var bank := mesh(fog_root,fog_shape,Vector3(13,1.5+index*2.8,1.1),Color("a6957e"))
		var haze: StandardMaterial3D = bank.material_override.duplicate()
		haze.albedo_texture = null
		haze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		haze.albedo_color.a = 0.13
		bank.material_override = haze
		fog_materials.append(haze)
	sign_text("ATMOS\nPRÉ-FILTRO > CARVÃO > TURBINA",Vector3(18,12.4,-3),30,GOLD)
	for height in [1.8,4.4,7.0,9.6]:
		box(Vector3(25,height,-1.3),Vector3(0.45,0.12,0.12),GOLD,true)

func _fan(at: Vector3, radius: float) -> void:
	var rim := TorusMesh.new()
	rim.inner_radius = radius
	rim.outer_radius = radius+0.12
	rim.rings = 20
	rim.ring_segments = 6
	var border := mesh(self,rim,at,Color("8e958e"))
	border.rotation.x = PI*0.5
	var rotor := Node3D.new()
	rotor.position = at+Vector3(0,0,0.12)
	add_child(rotor)
	fans.append(rotor)
	for index in range(6):
		var angle := index*TAU/6
		var blade := BoxMesh.new()
		blade.size = Vector3(radius*0.4,radius*0.9,0.08)
		var propeller := mesh(rotor,blade,Vector3(cos(angle)*radius*0.53,sin(angle)*radius*0.53,0),Color("5f8a94"))
		propeller.rotation.z = angle+0.5

func _make_gate() -> void:
	gate_height = 7.8 if station_id=="air" else 0
	var gate_x := 20.0 if station_id=="air" else 28.0
	gate_visual = Node3D.new()
	gate_visual.position = Vector3(gate_x,gate_height,0)
	add_child(gate_visual)
	gate = solid(Vector3(gate_x,gate_height+1.45,0),Vector3(0.42,2.9,2.6))
	var panel := BoxMesh.new()
	panel.size = Vector3(0.42,2.9,2.6)
	mesh(gate_visual,panel,Vector3(0,1.45,0),Color("5c626c"))
	for index in range(4):
		var strip := BoxMesh.new()
		strip.size = Vector3(0.46,0.08,2.7)
		mesh(gate_visual,strip,Vector3(0,0.25+index*0.7,0),GOLD,true)
	box(Vector3(gate_x,gate_height+3.2,-0.5),Vector3(0.8,0.3,3.7),Color("343a4a"))

func update_state(journey: Node, instant := false) -> void:
	var opened: bool = journey.value(station_id+"_open")==1
	if opened and not gate_opened:
		gate_opened = true
		gate.collision_layer = 0
		if instant:
			gate_visual.position.y = gate_height+3.1
		else:
			create_tween().tween_property(gate_visual,"position:y",gate_height+3.1,1.1)
	if station_id=="water":
		var flood_y := -3.1 if journey.value("water_drained")==1 else -0.7
		if flood_y!=flood_target:
			flood_target = flood_y
			if instant:flood.position.y = flood_y
			else:create_tween().tween_property(flood,"position:y",flood_y,1.4)
		if journey.value("water_pump")==1 and not pump_started:
			pump_started = true
			if instant:
				reservoir.scale.y = 3.3
				reservoir.position.y = 2.0
			else:
				var fill := create_tween().set_parallel(true)
				fill.tween_property(reservoir,"scale:y",3.3,1.4)
				fill.tween_property(reservoir,"position:y",2.0,1.4)
		reservoir_paint.albedo_color = Color("3e9eac") if journey.choices.water=="RESTORE" else Color("586b57")
		for key in valve_visuals:
			valve_visuals[key].rotation.z = journey.value(key)*PI*0.5
	elif station_id=="soil" and journey.choices.soil=="RESTORE" and not restoration_applied:
		restoration_applied = true
		for plant in young_plants:
			if instant:plant.scale = Vector3.ONE*0.68
			else:create_tween().tween_property(plant,"scale",Vector3.ONE*0.68,2.5)
	elif station_id=="air":
		fan_speed = 1.0 if journey.choices.air=="RESTORE" else 0.18
		for index in range(duct_shutters.size()):
			duct_shutters[index].rotation.y = PI*0.5 if index<journey.value("air_sequence") else 0
		if journey.choices.air=="RESTORE" and not restoration_applied:
			restoration_applied = true
			for haze in fog_materials:
				if instant:haze.albedo_color.a = 0.025
				else:create_tween().tween_property(haze,"albedo_color:a",0.025,2.0)

func _process(delta: float) -> void:
	elapsed += delta
	for fan in fans:
		fan.rotation.z += delta*fan_speed
	fog_root.position.x = sin(elapsed*0.2)*0.5
