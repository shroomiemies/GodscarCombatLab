class_name Player
extends CharacterBody3D

@export var walk_speed: float = 2.0
@export var jog_speed: float = 5.0
@export var run_speed: float = 6.0
@export var acceleration: float = 18.0
@export var gravity: float = 24.0
@export var camera_rig: CameraRig
@export var look_turn_speed: float = 18.0

@export var walk_blend_value: float = 0.3
@export var jog_blend_value: float = 0.8
@export var run_blend_value: float = 1.0

@export_group("Jump Tuning")
@export var jump_velocity: float = 8.0
@export var jump_start_duration: float = 0.18
@export var jump_buffer_time: float = 0.14
@export var coyote_time: float = 0.12

@export_group("Air Control")
@export var air_control_multiplier: float = 0.65

@export_group("Landing")
@export var heavy_land_velocity: float = 12.0
@export var impact_land_velocity: float = 20.0
@export var light_land_duration: float = 0.12
@export var heavy_land_duration: float = 0.35
@export var impact_land_duration: float = 0.65
@export var landing_movement_multiplier: float = 0.35

@onready var animation_controller: CharacterAnimationController = $AnimationController
@onready var targeting_controller: TargetingController = $TargetingController

var current_local_movement_input: Vector2 = Vector2.ZERO
var current_locomotion_blend_value: float = 0.0
var current_speed_fraction: float = 0.0
var movement_frame: MovementFrame
var movement_state: MovementState = MovementState.GROUNDED
var movement_state_time: float = 0.0
var was_on_floor: bool = false
var last_fall_speed: float = 0.0
var current_landing_type: LandingType = LandingType.LIGHT
var current_land_duration: float = 0.12
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0

enum MovementState {
	GROUNDED,
	JUMP_START,
	AIRBORNE,
	LANDING,
}

enum LandingType {
	LIGHT,
	HEAVY,
	IMPACT,
}

func _ready() -> void:
	movement_frame = MovementFrame.world()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lock_on"):
		_toggle_lock_on()
	
func _physics_process(delta: float) -> void:
	was_on_floor = is_on_floor()
	
	_update_timers(delta)
	_update_movement_frame()
	_update_look_facing(delta)
	_update_movement_state(delta)
	_apply_player_movement(delta)
	_update_fall_speed()

	move_and_slide()

	_after_movement(delta)
	_update_animation()
	
func _update_timers(delta: float) -> void:
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if coyote_timer > 0.0:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if is_on_floor() and movement_state != MovementState.JUMP_START:
		coyote_timer = coyote_time
	
func _update_movement_frame() -> void:
	# For now, the player uses normal world space.
	# Later, this will be replaced by a platform/deck-aware frame provider.
	movement_frame = MovementFrame.world()
	
func _update_look_facing(delta: float) -> void:
	var desired_forward := Vector3.ZERO

	if targeting_controller != null and targeting_controller.has_target():
		var target_point := targeting_controller.get_target_point()
		desired_forward = target_point - global_position
	else:
		if camera_rig == null:
			return

		desired_forward = -camera_rig.get_flat_camera_basis().z

	desired_forward.y = 0.0

	if desired_forward.length_squared() < 0.0001:
		return

	desired_forward = desired_forward.normalized()

	var target_yaw := atan2(-desired_forward.x, -desired_forward.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-look_turn_speed * delta))

func _update_movement_state(delta: float) -> void:
	movement_state_time += delta

	match movement_state:
		MovementState.GROUNDED:
			if _can_start_jump():
				_start_jump()
			elif not is_on_floor():
				_start_airborne()

		MovementState.JUMP_START:
			if movement_state_time >= jump_start_duration:
				_start_airborne()

		MovementState.AIRBORNE:
			if _can_start_jump():
				_start_jump()

		MovementState.LANDING:
			if _can_start_jump():
				_start_jump()
			elif movement_state_time >= current_land_duration:
				_start_grounded()

func _can_start_jump() -> bool:
	if jump_buffer_timer <= 0.0:
		return false

	if coyote_timer <= 0.0 and not is_on_floor():
		return false

	return true

func _update_fall_speed() -> void:
	if velocity.y < 0.0:
		last_fall_speed = max(last_fall_speed, abs(velocity.y))

func _after_movement(_delta: float) -> void:
	if movement_state == MovementState.AIRBORNE and is_on_floor():
		_start_landing()
	
func _start_grounded() -> void:
	movement_state = MovementState.GROUNDED
	movement_state_time = 0.0

	if animation_controller != null:
		animation_controller.travel_grounded()

func _start_jump() -> void:
	movement_state = MovementState.JUMP_START
	movement_state_time = 0.0

	jump_buffer_timer = 0.0
	coyote_timer = 0.0

	velocity.y = jump_velocity

	if animation_controller != null:
		animation_controller.travel_jump_start()

func _start_airborne() -> void:
	movement_state = MovementState.AIRBORNE
	movement_state_time = 0.0

	if animation_controller != null:
		animation_controller.travel_fall()

func _start_landing() -> void:
	movement_state = MovementState.LANDING
	movement_state_time = 0.0

	current_landing_type = _get_landing_type()

	match current_landing_type:
		LandingType.LIGHT:
			current_land_duration = light_land_duration
			print("Light landing. Fall speed: ", last_fall_speed)

		LandingType.HEAVY:
			current_land_duration = heavy_land_duration
			print("Heavy landing. Fall speed: ", last_fall_speed)

		LandingType.IMPACT:
			current_land_duration = impact_land_duration
			print("Impact landing. Fall speed: ", last_fall_speed)

	last_fall_speed = 0.0

	if animation_controller != null:
		animation_controller.travel_land()
	
func _get_landing_type() -> LandingType:
	if last_fall_speed >= impact_land_velocity:
		return LandingType.IMPACT

	if last_fall_speed >= heavy_land_velocity:
		return LandingType.HEAVY

	return LandingType.LIGHT
	
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
	current_locomotion_blend_value = jog_blend_value

	if Input.is_action_pressed("walk"):
		target_speed = walk_speed
		current_locomotion_blend_value = walk_blend_value
	elif Input.is_action_pressed("sprint"):
		target_speed = run_speed
		current_locomotion_blend_value = run_blend_value
		
	if movement_state == MovementState.LANDING:
		target_speed *= landing_movement_multiplier

	if input_vector.length() <= 0.0:
		current_locomotion_blend_value = 0.0

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
		return

	animation_controller.set_locomotion_input(
		current_local_movement_input,
		current_locomotion_blend_value
	)
	
func _toggle_lock_on() -> void:
	if targeting_controller == null:
		return

	var look_forward := -global_transform.basis.z

	if camera_rig != null:
		look_forward = -camera_rig.get_flat_camera_basis().z

	targeting_controller.toggle_lock_on(global_position, look_forward)

	if camera_rig == null:
		return

	if targeting_controller.has_target():
		camera_rig.set_lock_on_target(targeting_controller.current_target)
	else:
		camera_rig.clear_lock_on_target()
