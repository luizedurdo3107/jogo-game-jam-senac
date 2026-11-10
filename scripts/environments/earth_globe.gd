extends MeshInstance3D

var clouds: MeshInstance3D

func _ready() -> void:
	name = "Earth"
	mesh = _sphere(3.8)
	var surface := StandardMaterial3D.new()
	surface.albedo_texture = load("res://assets/processados/arca_rc5/earth_surface.png")
	surface.roughness = 0.73
	surface.metallic = 0.12
	surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material_override = surface
	rotation_degrees = Vector3(8,32,-12)
	clouds = MeshInstance3D.new()
	clouds.mesh = _sphere(3.85)
	var vapor := StandardMaterial3D.new()
	vapor.albedo_texture = load("res://assets/processados/arca_rc5/earth_clouds.png")
	vapor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vapor.roughness = 1.0
	vapor.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	clouds.material_override = vapor
	add_child(clouds)
	var halo := MeshInstance3D.new()
	var disc := QuadMesh.new()
	disc.size = Vector2(8.6,8.6)
	halo.mesh = disc
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glow.billboard_keep_scale = true
	glow.no_depth_test = false
	var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
	for row in range(128):
		for column in range(128):
			var radius := Vector2(column-63.5,row-63.5).length()/63.5
			var alpha := smoothstep(0.72,0.88,radius)*(1-smoothstep(0.88,1,radius))*0.34
			image.set_pixel(column,row,Color(0.15,0.58,1,alpha))
	glow.albedo_texture = ImageTexture.create_from_image(image)
	halo.material_override = glow
	halo.position.z = -0.3
	add_child(halo)

func _sphere(radius: float) -> SphereMesh:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius*2
	shape.radial_segments = 64
	shape.rings = 32
	return shape

func _process(delta: float) -> void:
	if not is_visible_in_tree():return
	rotation.y += delta*0.012
	clouds.rotation.y += delta*0.009
