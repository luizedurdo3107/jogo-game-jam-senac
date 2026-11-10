extends "res://scripts/environments/recife_environment.gd"

var region_id := "laboratory"
var core: Node3D

func _build_world() -> void:
	if region_id=="recife":
		super._build_world()
		floor_piece(22.65,23.75,0)
		sign_text("RUA DO BOM JESUS",Vector3(6,2.3,-3.7),24,GOLD)
		sign_text("MARCO ZERO",Vector3(5,0.15,1.3),24,TEAL)
		return
	var atmosphere := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("121c30") if region_id=="nova_eden" else Color("102825")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9dafc0")
	settings.ambient_light_energy = 0.65
	atmosphere.environment = settings
	add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-28,0)
	sun.light_energy = 1.2
	sun.light_color = Color("a9c6ce")
	add_child(sun)
	floor_piece(-2,22.65,0)
	floor_piece(23.75,38,0)
	if region_id!="nova_eden":
		floor_piece(10,26,-2.7)
		floor_piece(9.8,22.65,2.6,2.0)
		floor_piece(23.75,25,2.6,2.0)
		add_ladder(11,0,2.6)
		add_ladder(13.3,-2.7,0)
		add_ladder(24.5,-2.7,0)
		add_ladder(21,0,2.6)
	solid(Vector3(-1,3,0),Vector3(0.4,12,3))
	solid(Vector3(37,3,0),Vector3(0.4,12,3))
	if region_id=="nova_eden":
		floor_piece(22.65,23.75,0)
		box(Vector3(18,2.6,-3.5),Vector3(18,0.2,2),Color("394455"))
		for tower_index in range(8):
			var tower_x := tower_index*5.0
			var height := 9.0+float(tower_index%3)*2.0
			box(Vector3(tower_x,height*0.5,-7),Vector3(4.6,height,5),Color("29334a"))
			box(Vector3(tower_x,height-0.2,-4.4),Vector3(4.7,0.2,0.2),Color("b347b8"),true)
			for row in range(5):
				for column in range(4):
					box(Vector3(tower_x+(column-1.5)*0.85,row*1.6+1.5,-4.4),Vector3(0.45,0.75,0.06),TEAL.darkened(0.25),true)
			box(Vector3(tower_x-2,2.5,-3.8),Vector3(0.3,5,0.3),Color("72798a"))
			sign_text("O₂ / NEXUS",Vector3(tower_x,1.8,-3.6),23,GOLD)
		for rail_x in range(0,36,2):
			box(Vector3(rail_x,3.35,-1.6),Vector3(0.06,1.3,0.06),GOLD)
		box(Vector3(18,3.95,-1.6),Vector3(18,0.08,0.08),GOLD)
		sign_text("NOVA ÉDEN / ACESSO CONTROLADO",Vector3(7,6,-3.8),35,TEAL)
		sign_text("MANUTENÇÃO →",Vector3(27,4.2,-1.7),28,GOLD)
	else:
		for bay_index in range(7):
			var bay_x := bay_index*5.0
			box(Vector3(bay_x,3.9,-6),Vector3(4.7,9,0.5),Color("263e43"))
			box(Vector3(bay_x-2.4,3.8,-4),Vector3(0.28,9,2.8),Color("717783"))
			box(Vector3(bay_x,7.9,-3),Vector3(5.1,0.3,4),Color("4d5d65"))
			box(Vector3(bay_x,2.6,-3.7),Vector3(4.8,0.14,0.35),GOLD)
			for shelf in range(4):
				box(Vector3(bay_x,0.8+shelf*1.4,-4.6),Vector3(3.6,0.12,0.6),Color("6f7779"))
				for jar in range(4):
					var vial := CylinderMesh.new()
					vial.top_radius = 0.12
					vial.bottom_radius = 0.15
					vial.height = 0.55
					vial.radial_segments = 8
					mesh(self,vial,Vector3(bay_x+(jar-1.5)*0.7,1.1+shelf*1.4,-4.3),Color("4e9c80"))
		core = Node3D.new()
		core.position = Vector3(15,0,-3.5)
		add_child(core)
		var glass := CylinderMesh.new()
		glass.top_radius = 2.1
		glass.bottom_radius = 2.1
		glass.height = 7
		glass.radial_segments = 32
		var capsule := mesh(core,glass,Vector3(0,3.5,0),Color("328e85"))
		var transparent: StandardMaterial3D = capsule.material_override.duplicate()
		transparent.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		transparent.albedo_color.a = 0.16
		capsule.material_override = transparent
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.13
		trunk.bottom_radius = 0.4
		trunk.height = 4.7
		mesh(core,trunk,Vector3(0,2.35,0),Color("615a43"))
		for branch_index in range(14):
			var leaf := PrismMesh.new()
			leaf.size = Vector3(1.2,1.1,0.22)
			var angle := branch_index*2.4
			var instance := mesh(core,leaf,Vector3(sin(angle)*1.1,3.6+cos(angle)*1.1,cos(angle)*0.8),Color("69a768"))
			instance.rotation.z = sin(angle)*0.9
		for ring_y in [0.2,3.1,6.9]:
			var ring := TorusMesh.new()
			ring.inner_radius = 1.95
			ring.outer_radius = 2.1
			ring.rings = 24
			ring.ring_segments = 8
			mesh(core,ring,Vector3(0,ring_y,0),TEAL,true)
		sign_text("GAIA / ARQUIVO VIVO",Vector3(14,7.7,-2.8),36,TEAL)
		sign_text("CÉLULAS ↓",Vector3(17,-0.6,-2.7),26,GOLD)
	_make_story_gate()
	circuit = Node3D.new()
	add_child(circuit)
	circuit.hide()
	for path_x in range(7,29,2):
		var link := BoxMesh.new()
		link.size = Vector3(1.9,0.06,0.06)
		mesh(circuit,link,Vector3(path_x,3.2,-0.6),TEAL,true)

func _make_story_gate() -> void:
	gate_visual = Node3D.new()
	gate_visual.name = "GatePanel"
	gate_visual.position.x = 28
	add_child(gate_visual)
	gate = solid(Vector3(28,1.65,0),Vector3(0.45,3.3,2.8))
	var shape := BoxMesh.new()
	shape.size = Vector3(0.45,3.3,2.8)
	mesh(gate_visual,shape,Vector3(0,1.65,0),Color("465563"))
	for stripe in range(6):
		var bar := BoxMesh.new()
		bar.size = Vector3(0.48,0.07,2.85)
		mesh(gate_visual,bar,Vector3(0,0.25+stripe*0.5,0),GOLD,true)
	gate_animation = AnimationPlayer.new()
	add_child(gate_animation)
	var opening := Animation.new()
	opening.length = 1.2
	var track := opening.add_track(Animation.TYPE_VALUE)
	opening.track_set_path(track,NodePath("GatePanel:position"))
	opening.track_insert_key(track,0,Vector3(28,0,0))
	opening.track_insert_key(track,1.2,Vector3(28,3.6,0))
	var library := AnimationLibrary.new()
	library.add_animation("open_gate",opening)
	gate_animation.add_animation_library("",library)
