extends SceneTree

const DESTINATION := "res://assets/processados/arca_rc5/"
const CONTINENTS := [
	[Vector2(-168,70),Vector2(-140,71),Vector2(-126,59),Vector2(-124,47),Vector2(-117,31),Vector2(-99,17),Vector2(-87,19),Vector2(-81,26),Vector2(-82,35),Vector2(-64,45),Vector2(-54,54),Vector2(-76,72),Vector2(-111,77)],
	[Vector2(-81,11),Vector2(-71,12),Vector2(-61,8),Vector2(-50,1),Vector2(-35,-7),Vector2(-40,-23),Vector2(-53,-35),Vector2(-68,-55),Vector2(-73,-40),Vector2(-80,-9)],
	[Vector2(-17,35),Vector2(0,37),Vector2(11,33),Vector2(32,31),Vector2(43,12),Vector2(51,10),Vector2(42,-12),Vector2(32,-27),Vector2(19,-35),Vector2(11,-18),Vector2(7,4),Vector2(-15,14)],
	[Vector2(-11,36),Vector2(-10,44),Vector2(7,52),Vector2(8,60),Vector2(30,71),Vector2(65,75),Vector2(110,72),Vector2(160,60),Vector2(172,51),Vector2(143,43),Vector2(130,32),Vector2(120,22),Vector2(108,5),Vector2(99,14),Vector2(80,9),Vector2(70,24),Vector2(51,12),Vector2(35,31),Vector2(23,38),Vector2(14,40),Vector2(2,37)],
	[Vector2(113,-22),Vector2(128,-12),Vector2(141,-11),Vector2(153,-26),Vector2(146,-39),Vector2(129,-33),Vector2(115,-35)],
	[Vector2(-53,60),Vector2(-43,60),Vector2(-20,76),Vector2(-35,83),Vector2(-61,79)],
	[Vector2(46,-13),Vector2(50,-15),Vector2(48,-26),Vector2(44,-25)]
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(DESTINATION)
	var noise := FastNoiseLite.new()
	noise.seed = 2187
	noise.frequency = 3.0
	noise.fractal_octaves = 4
	var clouds := FastNoiseLite.new()
	clouds.seed = 404
	clouds.frequency = 4.0
	clouds.fractal_octaves = 5
	var surface := Image.create(1024,512,false,Image.FORMAT_RGB8)
	var cloud_layer := Image.create(1024,512,false,Image.FORMAT_RGBA8)
	for row in range(surface.get_height()):
		var latitude := 90.0-row*180.0/511
		for column in range(surface.get_width()):
			var longitude := column*360.0/1023-180
			var direction := Vector3(cos(deg_to_rad(latitude))*cos(deg_to_rad(longitude)),sin(deg_to_rad(latitude)),cos(deg_to_rad(latitude))*sin(deg_to_rad(longitude)))
			var relief := noise.get_noise_3dv(direction)
			var point := Vector2(longitude+relief*2.8,latitude+relief*1.8)
			var land := false
			for polygon in CONTINENTS:
				if Geometry2D.is_point_in_polygon(point,PackedVector2Array(polygon)):
					land = true
					break
			var ink := Color("082a57").lerp(Color("145c83"),clampf(relief+0.4,0,1))
			if land:
				ink = Color("285349").lerp(Color("659267"),clampf(relief+0.5,0,1))
				if absf(latitude)>14 and absf(latitude)<33:ink = ink.lerp(Color("b49b6b"),0.7 if longitude>-20 and longitude<60 else 0.25)
				if relief>0.35:ink = ink.lerp(Color("a59b82"),0.55)
			if absf(latitude)>72+relief*8 or latitude< -70:ink = ink.lerp(Color("d5e5e9"),0.95)
			surface.set_pixel(column,row,ink)
			var vapor := clouds.get_noise_3dv(direction+Vector3(relief*0.18,0,0))
			var opacity := smoothstep(0.04,0.46,vapor)*0.87
			cloud_layer.set_pixel(column,row,Color(0.92,0.97,1,opacity))
	surface.generate_mipmaps()
	cloud_layer.generate_mipmaps()
	assert(surface.save_png(DESTINATION+"earth_surface.png")==OK)
	assert(cloud_layer.save_png(DESTINATION+"earth_clouds.png")==OK)
	print("ARCA RC5 / superfície e nuvens procedurais: 1024 × 512")
	quit()
