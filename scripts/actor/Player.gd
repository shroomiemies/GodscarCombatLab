class_name Player
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var gravity: float = 24.0

var movement_frame: MovementFrame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	movement_frame = MovementFrame.world()
	
func _physics_process(delta: float) -> void:
	_update_movement_frame()
	_apply_player_movement(delta)
	move_and_slide()
	
func _update_movement_frame() -> void:
	# For now, the player uses normal world space.
	# Later, this will be replaced by a platform/deck-aware frame provider.
	movement_frame = MovementFrame.world()
	
func _apply_player_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	
	var local_move := Vector3(input_vector.x,0,input_vector.y)
	
	if local_move.length() > 1.0:
		local_move.normalized()
	
	var world_move := movement_frame.local_direction_to_world(local_move)
	var desired_horizontal_velocity := world_move * move_speed
	
	velocity.x = move_toward(velocity.x, desired_horizontal_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_horizontal_velocity.z, acceleration * delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
	
