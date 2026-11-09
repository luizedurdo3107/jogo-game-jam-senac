extends Node

var soundscape: Node
var actor: Node
var sprite: Node
var last_position: Variant
var was_grounded := false
var travelled := 0.0
var rung_distance := 0.0
var airborne := 0.0
var previous_vertical := 0.0
var surface := "concrete"

func _ready() -> void:
	actor = get_parent()
	sprite = actor.sprite
	last_position = actor.global_position
	was_grounded = actor.is_on_floor()
	sprite.frame_changed.connect(_animation_contact)

func _physics_process(delta: float) -> void:
	var point: Variant = actor.global_position
	var displacement: Variant = point-last_position
	last_position = point
	var is_3d := actor is Node3D
	var locked: bool = actor.locked if is_3d else (actor.blocked or GameState.input_locked)
	var grounded: bool = actor.is_on_floor()
	if locked or get_tree().paused or displacement.length()>(2.0 if is_3d else 90.0):
		travelled = 0
		rung_distance = 0
		airborne = 0
		was_grounded = grounded
		return
	var scale := 1.0 if is_3d else 43.0
	if actor.climbing:
		rung_distance += absf(displacement.y)/scale
		if rung_distance>=0.45:
			rung_distance = 0
			soundscape.emit("ladder",point)
	else:rung_distance = 0
	if grounded and not actor.climbing:
		surface = floor_surface()
		travelled += absf(displacement.x)/scale
		if not was_grounded and airborne>0.1:
			soundscape.emit("land_"+surface,point,clampf(absf(previous_vertical)/scale*0.25-2,-4,1))
		airborne = 0
	elif not actor.climbing:
		airborne += delta
		if was_grounded and (actor.velocity.y>2 if is_3d else actor.velocity.y< -100):soundscape.emit("jump",point)
	was_grounded = grounded
	previous_vertical = actor.velocity.y
	if absf(displacement.x)<0.001:travelled = minf(travelled,0.08)

func _animation_contact() -> void:
	if not is_instance_valid(actor) or not is_instance_valid(soundscape):return
	if sprite.animation!="walk" or sprite.frame not in [1,5] or not actor.is_on_floor() or actor.climbing or travelled<0.15:return
	travelled = 0
	surface = floor_surface()
	soundscape.emit("step_"+surface,actor.global_position)

func floor_surface() -> String:
	var collider: Object
	if actor is Node3D:
		var query := PhysicsRayQueryParameters3D.create(actor.global_position+Vector3(0,0.15,0),actor.global_position-Vector3(0,0.3,0),1,[actor.get_rid()])
		var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():collider = hit.collider
	else:
		var query := PhysicsRayQueryParameters2D.create(actor.global_position-Vector2(0,4),actor.global_position+Vector2(0,15),9,[actor.get_rid()])
		var hit: Dictionary = actor.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():collider = hit.collider
	var result := str(collider.get_meta("audio_surface","concrete")) if collider else "concrete"
	return result if result in ["concrete","metal","wet"] else "concrete"
