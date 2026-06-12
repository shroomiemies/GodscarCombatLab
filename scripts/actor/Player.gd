class_name Player
extends CharacterBody3D

@export var walk_speed: float = 2.0
@export var jog_speed: float = 5.0
@export var run_speed: float = 6.0
@export var acceleration: float = 18.0
@export var gravity: float = 24.0
@export var camera_rig: CameraRig
@export var look_turn_speed: float = 18.0

@onready var animation_controller: CharacterAnimationController = $AnimationController

var current_local_movement_input: Vector2 = Vector2.ZERO
var current_speed_fraction: float = 0.0
var movement_frame: MovementFrame

func _ready() -> void:
	movement_frame = MovementFrame.world()
	
func _physics_process(delta: float) -> void:
	_update_movement_frame()
	_update_look_facing(delta)
	_apply_player_movement(delta)
	move_and_slide()
	_update_animation()
	
func _update_movement_frame() -> void:
	# For now, the player uses normal world space.
	# Later, this will be replaced by a platform/deck-aware frame provider.
	movement_frame = MovementFrame.world()
	
func _update_look_facing(delta: float) -> void:
	if camera_rig == null:
		return

	var camera_forward := -camera_rig.get_flat_camera_basis().z

	if camera_forward.length_squared() < 0.0001:
		return

	var target_yaw := atan2(-camera_forward.x, -camera_forward.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-look_turn_speed * delta))
	
func _apply_player_movement(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	
	# Input.get_vector gives W/forward as negative Y.
	# Animation space uses forward as positive Y.
	current_local_movement_input = Vector2(input_vector.x, -input_vector.y)
	
	var local_move := Vector3(input_vector.x,0,input_vector.y)
	
	if local_move.length() > 1.0:
		local_move = local_move.normalized()
		
	current_local_movement_input = Vector2(input_vector.x, -input_vector.y)

	var target_speed := jog_speed

	if Input.is_action_pressed("walk"):
		target_speed = walk_speed
	elif Input.is_action_pressed("sprint"):
		target_speed = run_speed
	else:
		target_speed = jog_speed

	current_speed_fraction = 0.0

	if input_vector.length() > 0.0:
		current_speed_fraction = clamp(target_speed / run_speed, 0.0, 1.0)
	
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x

	forward.y = 0.0
	right.y = 0.0

	forward = forward.normalized()
	right = right.normalized()

	var movement_basis := Basis()
	movement_basis.x = right
	movement_basis.y = movement_frame.up
	movement_basis.z = -forward
	
	if camera_rig != null:
		movement_basis = camera_rig.get_flat_camera_basis()
	
	var world_move := movement_basis * local_move
	var desired_horizontal_velocity := world_move * target_speed
	
	velocity.x = move_toward(velocity.x, desired_horizontal_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_horizontal_velocity.z, acceleration * delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
	
func _update_animation() -> void:
	if animation_controller == null:
		print("No animation_controller found.")
		return

	#print("Anim input: ", current_local_movement_input, " speed fraction: ", current_speed_fraction)

	animation_controller.set_locomotion_input(
		current_local_movement_input,
		current_speed_fraction
	)
