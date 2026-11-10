extends Node3D

var environment: Node3D
var item: Dictionary
var world: Node3D
var indicator: MeshInstance3D
var scanner: MeshInstance3D
var elapsed := 0.0

func _ready() -> void:
	var bezel := BoxMesh.new()
	bezel.size = Vector3(0.48,0.43,0.06)
	environment.mesh(self,bezel,Vector3(0,0.62,0.2),Color("1a2534"))
	var display := BoxMesh.new()
	display.size = Vector3(0.35,0.25,0.018)
	environment.mesh(self,display,Vector3(0,0.65,0.24),Color("23434a"),true)
	for button_index in range(3):
		var key := CylinderMesh.new()
		key.top_radius = 0.035
		key.bottom_radius = 0.035
		key.height = 0.035
		key.radial_segments = 8
		var knob: MeshInstance3D = environment.mesh(self,key,Vector3((button_index-1)*0.12,0.35,0.23),SignalTheme.GOLD)
		knob.rotation.x = PI*0.5
	var light := SphereMesh.new()
	light.radius = 0.045
	light.height = 0.09
	light.radial_segments = 8
	light.rings = 4
	indicator = environment.mesh(self,light,Vector3(0.22,0.92,0.25),SignalTheme.GOLD,true)
	var scan := BoxMesh.new()
	scan.size = Vector3(0.32,0.014,0.02)
	scanner = environment.mesh(self,scan,Vector3(0,0.65,0.26),SignalTheme.TEAL,true)
	for edge_x in [-0.22,0.22]:
		for edge_y in [0.1,0.8]:
			var bolt := BoxMesh.new()
			bolt.size = Vector3(0.035,0.035,0.025)
			environment.mesh(self,bolt,Vector3(edge_x,edge_y,0.23),Color("a7a4a4"))

func _process(delta: float) -> void:
	elapsed += delta
	scanner.position.y = 0.65+sin(elapsed*2.2)*0.09
	var done := GameState.has_flag(str(item.get("done","")))
	if world.get("station_id")!=null:done = world.journey.value(str(item.get("command","")))==1
	indicator.material_override = environment.material(SignalTheme.TEAL if done else SignalTheme.GOLD,true)
	indicator.scale = Vector3.ONE*(1.0 if done else 0.8+sin(elapsed*3)*0.15)
