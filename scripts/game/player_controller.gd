extends CharacterBody3D

const SPEED := 4.3
const JUMP := 6.7
var world: Node3D
var sprite: AnimatedSprite3D
var climbing := false
var ladder: Dictionary = {}
var coyote := 0.0
var buffer := 0.0
var locked := false
var hidden := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.55
	collision.shape = capsule
	collision.position.y = 0.78
	add_child(collision)
	sprite = AnimatedSprite3D.new()
	sprite.sprite_frames = preload("res://assets/processados/protagonista_provisorio/sprite_frames.tres")
	sprite.pixel_size = 0.008
	sprite.position.y = 0.835
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.play("idle")
	add_child(sprite)
	var shadow := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.28
	shape.bottom_radius = 0.28
	shape.height = 0.012
	shape.radial_segments = 16
	shadow.mesh = shape
	shadow.position.y = 0.02
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color("242c3b")
	shadow.material_override = ink
	add_child(shadow)

func _physics_process(delta: float) -> void:
	if locked:
		velocity = Vector3.ZERO
		sprite.play("idle")
		return
	var horizontal := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("climb_down", "climb_up")
	coyote = 0.14 if is_on_floor() else maxf(0, coyote - delta)
	buffer = 0.14 if Input.is_action_just_pressed("jump") else maxf(0, buffer - delta)
	if not climbing and not is_zero_approx(vertical) and world:
		for candidate in world.ladders:
			if absf(position.x - candidate.x) < 0.52 and position.y >= candidate.bottom - 0.15 and position.y <= candidate.top + 0.15:
				if vertical > 0 and position.y < candidate.top - 0.05 or vertical < 0 and position.y > candidate.bottom + 0.05:
					ladder = candidate
					climbing = true
					for platform in world.platforms:
						add_collision_exception_with(platform)
					break
	if climbing:
		position.x = move_toward(position.x, float(ladder.x), delta * 7)
		velocity = Vector3(0, vertical * 2.8, 0)
		if absf(horizontal)>0.1:
			var query := PhysicsRayQueryParameters3D.create(global_position+Vector3(0,0.2,0),global_position-Vector3(0,0.24,0),1,[get_rid()])
			var landing := get_world_3d().direct_space_state.intersect_ray(query)
			if not landing.is_empty() and landing.normal.y>0.7:
				position.y = landing.position.y+0.04
				_end_climb()
				velocity = Vector3(horizontal*SPEED,0,0)
		if climbing and (position.y >= float(ladder.top) + 0.04 or position.y <= float(ladder.bottom) + 0.04 and vertical < 0 or buffer > 0):
			if position.y >= float(ladder.top) + 0.04 and ladder.has("exit_x"):
				position.x = float(ladder.exit_x)
			_end_climb()
			velocity.y = JUMP if buffer > 0 else 0
			buffer = 0
	else:
		velocity.x = move_toward(velocity.x, horizontal * SPEED, delta * 28)
		velocity.y -= 18 * delta
		if buffer > 0 and coyote > 0:
			velocity.y = JUMP
			buffer = 0
			coyote = 0
		if Input.is_action_just_released("jump") and velocity.y > 0:
			velocity.y *= 0.45
	move_and_slide()
	position.z = 0
	velocity.z = 0
	if absf(horizontal) > 0.1:
		sprite.flip_h = horizontal < 0
	if climbing or not is_on_floor():
		sprite.pause()
	else:
		sprite.play("walk" if absf(velocity.x) > 0.2 else "idle")
	if position.y < -7:
		position = Vector3(10, 0.2, 0)
		velocity = Vector3.ZERO
		_end_climb()

func _end_climb() -> void:
	climbing = false
	if world:
		for platform in world.platforms:
			remove_collision_exception_with(platform)
