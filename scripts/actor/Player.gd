class_name Player
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var gravity: float = 24.0
@export var camera_rig: CameraRig
@export var turn_speed: float = 12.0

@onready var animation_controller: CharacterAnimationController = $AnimationController

var movement_frame: MovementFrame

func _ready() -> void:
	movement_frame = MovementFrame.world()
	
func _physics_process(delta: float) -> void:
	_update_movement_frame()
	_apply_player_movement(delta)
	move_and_slide()
	_update_animation()
	
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
		local_move = local_move.normalized()
	
	var movement_basis := movement_frame.basis
	
	if camera_rig != null:
		movement_basis = camera_rig.get_flat_camera_basis()
	
	var world_move := movement_basis * local_move
	var desired_horizontal_velocity := world_move * move_speed
	
	velocity.x = move_toward(velocity.x, desired_horizontal_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_horizontal_velocity.z, acceleration * delta)
	
	_update_facing(world_move, delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
	
func _update_facing(world_move: Vector3, delta: float) -> void:
	if world_move.length_squared() < 0.0001:
		return
		
	var target_yaw := atan2(-world_move.x, -world_move.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))
	
func _update_animation () -> void:
	if animation_controller == null:
		return
		
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	animation_controller.update_locomotion(horizontal_velocity.length())
