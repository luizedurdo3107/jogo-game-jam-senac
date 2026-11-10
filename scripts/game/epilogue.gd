extends Node3D

var environment: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var return_button: Button
var camera: Camera3D
var ship: Node3D
var space: Node3D
var mars: Node3D
var planet: MeshInstance3D
var aliens: Array[Node3D] = []
var shots: Array = []
var shot := -1
var elapsed := 0.0
var complete := false
var subtitle: Label
var title: Label
var actions: HBoxContainer
var earth := true
var shared_garden: Node3D
var sky_settings: Environment
var space_light: DirectionalLight3D

func _ready() -> void:
	if StationJourney.stage!="ending" or StationJourney.ending().is_empty():
		SceneRouter.menu()
		return
	GameState.gaia_active = false
	earth = StationJourney.ending()=="ending_a"
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/cinematics.json"))
	shots = story.earth if earth else story.mars
	if not earth and StationJourney.value("legacy_departure")==1:shots[0] = story.legacy_mars_opening
	environment = Node3D.new()
	environment.set_script(preload("res://scripts/environments/recife_environment.gd"))
	add_child(environment)
	environment.open_gate()
	if earth:
		environment.show_decision(true)
		if StationJourney.choices.soil=="EXODUS":
			for plant in environment.plants:plant.scale = Vector3.ONE*0.4
	player = CharacterBody3D.new()
	player.set_script(preload("res://scripts/game/player_controller.gd"))
	player.world = environment
	player.position = Vector3(5,0.1,0)
	player.locked = true
	add_child(player)
	player.set_physics_process(false)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	camera.position = Vector3(8,8,22)
	add_child(camera)
	camera.look_at(Vector3(6,2,-1))
	if not earth:_space_and_mars()
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = SignalTheme.create()
	hud.add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 24
	root.add_child(top)
	title = SignalTheme.label("",26,SignalTheme.GOLD)
	top.add_child(title)
	var bottom := PanelContainer.new()
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -178
	bottom.offset_bottom = -24
	root.add_child(bottom)
	var layout := VBoxContainer.new()
	bottom.add_child(layout)
	subtitle = SignalTheme.label("",24)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation",12)
	layout.add_child(actions)
	var skip := Button.new()
	skip.text = "Avançar cena  [E]"
	skip.custom_minimum_size.y = 54
	skip.pressed.connect(_next)
	actions.add_child(skip)
	AudioDirector.attach_world(self,StationJourney.ending())
	_next()

func _space_and_mars() -> void:
	ship = Node3D.new()
	ship.set_script(preload("res://scripts/environments/ark_ship.gd"))
	ship.position = Vector3(24,3,-3)
	add_child(ship)
	space = Node3D.new()
	add_child(space)
	planet = MeshInstance3D.new()
	planet.set_script(preload("res://scripts/environments/earth_globe.gd"))
	planet.position = Vector3(10,2,-10)
	space.add_child(planet)
	space_light = DirectionalLight3D.new()
	space_light.rotation_degrees = Vector3(-18,-48,0)
	space_light.light_color = Color("e0efff")
	space_light.light_energy = 1.6
	space.add_child(space_light)
	for child in environment.get_children():
		if child is WorldEnvironment:sky_settings = child.environment
	var random := RandomNumberGenerator.new()
	random.seed = 404
	for star_index in range(120):
		var star := SphereMesh.new()
		star.radius = 0.025+float(star_index%3)*0.015
		star.height = star.radius*2
		star.radial_segments = 4
		star.rings = 2
		environment.mesh(space,star,Vector3(random.randf_range(-15,45),random.randf_range(-12,24),-18),SignalTheme.PAPER,true)
	mars = Node3D.new()
	add_child(mars)
	var ground := BoxMesh.new()
	ground.size = Vector3(70,0.5,30)
	environment.mesh(mars,ground,Vector3(15,-0.25,-6),Color("985b47"))
	for hill_index in range(9):
		var hill := PrismMesh.new()
		hill.size = Vector3(6,4+hill_index%3,5)
		environment.mesh(mars,hill,Vector3(hill_index*5-5,1,-18),Color("6d4a4c"))
	for house_index in range(5):
		var shelter := SphereMesh.new()
		shelter.radius = 1.8
		shelter.height = 3.5
		environment.mesh(mars,shelter,Vector3(house_index*4+6,1,-7),Color("6e8791"))
		var doorway := BoxMesh.new()
		doorway.size = Vector3(0.8,1.6,0.2)
		environment.mesh(mars,doorway,Vector3(house_index*4+6,0.8,-5.4),SignalTheme.TEAL,true)
	for alien_index in range(3):
		var alien := Node3D.new()
		alien.position = Vector3(14+alien_index*2,0,0)
		mars.add_child(alien)
		aliens.append(alien)
		var alien_body := CapsuleMesh.new()
		alien_body.radius = 0.23
		alien_body.height = 1.3
		environment.mesh(alien,alien_body,Vector3(0,0.7,0),Color("8ab5ad"))
		var head := SphereMesh.new()
		head.radius = 0.33
		head.height = 0.6
		environment.mesh(alien,head,Vector3(0,1.5,0),Color("c8c58b"))
		for eye_x in [-0.12,0.12]:
			var eye := SphereMesh.new()
			eye.radius = 0.06
			eye.height = 0.11
			environment.mesh(alien,eye,Vector3(eye_x,1.55,0.27),Color("202c45"))
		var arm := CapsuleMesh.new()
		arm.radius = 0.065
		arm.height = 0.7
		var greeting: MeshInstance3D = environment.mesh(alien,arm,Vector3(-0.35,1.2,0),Color("8ab5ad"))
		greeting.name = "Greeting"
		greeting.rotation.z = 0.7
	shared_garden = Node3D.new()
	shared_garden.position = Vector3(12.7,0,-0.1)
	mars.add_child(shared_garden)
	var basin := CylinderMesh.new()
	basin.top_radius = 0.35
	basin.bottom_radius = 0.24
	basin.height = 0.3
	environment.mesh(shared_garden,basin,Vector3(0,0.15,0),Color("8eb5bb"))
	for leaf_index in range(4):
		var leaf := PrismMesh.new()
		leaf.size = Vector3(0.18,0.65,0.08)
		var young_leaf: MeshInstance3D = environment.mesh(shared_garden,leaf,Vector3((leaf_index-1.5)*0.09,0.6,0),Color("82ac72"))
		young_leaf.rotation.z = (leaf_index-1.5)*0.35
	space.hide()
	mars.hide()

func _process(delta: float) -> void:
	if complete or shot<0:return
	elapsed += delta
	var progress := clampf(elapsed/float(shots[shot].seconds),0,1)
	if earth:
		camera.position.x = lerpf(camera.position.x,7.0+shot*4.5+progress*1.3,delta*0.8)
		environment.water.material_override = environment.material(Color("285b6a").lerp(Color("3e8d94"),progress))
	else:
		match shot:
			0:
				player.position.x = 8+progress*13
				player.sprite.play("walk")
			1:
				player.hide()
				ship.position = Vector3(24+progress*3,3+progress*13,-3-progress*4)
				ship.rotation.z = progress*0.16
				camera.position = ship.position+Vector3(1,4.8,24)
				camera.look_at(ship.position+Vector3(-1,0,-1))
			2:
				planet.scale = Vector3.ONE*lerpf(1.0,0.5,progress)
				ship.position = Vector3(20+progress*1.7,5+sin(progress*PI)*0.3,-1)
			3:
				planet.scale = Vector3.ONE*lerpf(0.5,0.15,progress)
				ship.position.x = 21.7+progress*7
			4:
				ship.position = Vector3(24,12-progress*9,-3)
				ship.set_flight(progress<0.8)
			5,6,7:
				player.show()
				player.position = Vector3(11,0.05,0)
				for index in range(aliens.size()):
					aliens[index].position.x = 14+index*2-(progress*1.5 if shot==5 else 1.5)
					aliens[index].get_node("Greeting").rotation.z = 0.9+sin(elapsed*3)*0.3
				shared_garden.visible = shot>=6
				shared_garden.scale = Vector3.ONE*(0.6+progress*0.4 if shot==7 else 0.6)
	if elapsed>=float(shots[shot].seconds):_next()

func _next() -> void:
	if complete:return
	shot += 1
	elapsed = 0
	if shot>=shots.size():
		complete = true
		title.text = "FIM / "+("A TERRA AINDA RESPONDE" if earth else "UM LAR COMPARTILHADO")
		subtitle.text = "Água, sementes e ar: %d núcleos ficaram com o Recife; %d seguiram para a ARCA. Cada escolha continua fazendo diferença."%[StationJourney.choices.values().count("RESTORE"),StationJourney.choices.values().count("EXODUS")]
		for child in actions.get_children():
			actions.remove_child(child)
			child.queue_free()
		return_button = Button.new()
		return_button.text = "Fim da transmissão · Menu"
		return_button.custom_minimum_size.y = 58
		return_button.pressed.connect(SceneRouter.menu)
		actions.add_child(return_button)
		return_button.grab_focus()
		return
	title.text = str(shots[shot].title)
	subtitle.text = str(shots[shot].text)
	if earth and shot==1 and StationJourney.choices.water=="EXODUS":subtitle.text = "O núcleo de água seguiu para a ARCA. No Recife, a comunidade inicia reparos manuais e recupera o primeiro canal."
	if earth and shot==2 and StationJourney.choices.soil=="EXODUS":subtitle.text = "O cofre de sementes partiu. Nara e Lyra compartilham as últimas mudas locais. A recuperação será mais lenta."
	if not earth:
		environment.visible = shot<2
		space.visible = shot in [2,3]
		mars.visible = shot>=4
		player.visible = shot==0 or shot>=5
		camera.position = Vector3(17,6,22)
		camera.look_at(Vector3(15,2,-2))
		ship.rotation = Vector3(0,-0.22,0)
		ship.set_flight(shot in [1,2,3,4])
		sky_settings.background_color = Color("020714") if shot in [2,3] else Color("212740")
		sky_settings.ambient_light_energy = 0.13 if shot in [2,3] else 0.38
		if shot in [2,3]:
			camera.size = 16
			camera.position = Vector3(16,7,24)
			camera.look_at(Vector3(14,1,-4))
		if shot==2:
			ship.position = Vector3(20,5,-1)
			planet.scale = Vector3.ONE
		if shot==4:planet.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not complete:_next()
