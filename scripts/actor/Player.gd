class_name Player
extends CharacterBody3D

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

@export_group("Movement")
@export var walk_speed: float = 2.0
@export var jog_speed: float = 5.0
@export var run_speed: float = 6.0
@export var ground_acceleration: float = 18.0
@export var air_acceleration: float = 5.0
@export var landing_acceleration: float = 8.0
@export var ground_deceleration: float = 22.0
@export var air_deceleration: float = 0.0
@export_group("Sprint")
@export var sprint_attack_min_speed: float = 5.15

@export_group("Landing")
@export var heavy_land_velocity: float = 12.0
@export var impact_land_velocity: float = 20.0
@export var light_land_duration: float = 0.12
@export var heavy_land_duration: float = 0.35
@export var impact_land_duration: float = 0.65
@export var landing_movement_multiplier: float = 0.35

@onready var animation_controller: CharacterAnimationController = $AnimationController
@onready var targeting_controller: TargetingController = $TargetingController
@onready var combat_controller: CombatController = $CombatController
@onready var weapon_loadout_controller: WeaponLoadoutController = $WeaponLoadoutController

var current_local_movement_input: Vector2 = Vector2.ZERO
var current_locomotion_blend_value: float = 0.0
var current_speed_fraction: float = 0.0
var sprint_enabled: bool = false
var is_sprinting: bool = false
var movement_frame: MovementFrame
var movement_state: MovementState = MovementState.GROUNDED
var locomotion_velocity: Vector3 = Vector3.ZERO
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

	if event.is_action_pressed("sprint"):
		_enable_sprint()
	
	if event.is_action_released("move_forward") or event.is_action_released("move_left") or event.is_action_released("move_right") or event.is_action_released("move_backward"):
		_disable_sprint()
		
	if event.is_action_pressed("walk"):
		_disable_sprint()

	if event.is_action_pressed("attack_main"):
		_try_main_attack()

	if event.is_action_pressed("attack_offhand"):
		_begin_strong_attack()

	if event.is_action_released("attack_offhand"):
		_release_strong_attack()
		
	if event.is_action_pressed("weapon_style_1"):
		_equip_weapon_style_index(0)

	if event.is_action_pressed("weapon_style_2"):
		_equip_weapon_style_index(1)

	if event.is_action_pressed("weapon_style_3"):
		_equip_weapon_style_index(2)

	if event.is_action_pressed("weapon_style_4"):
		_equip_weapon_style_index(3)

	if event.is_action_pressed("weapon_next"):
		_equip_next_weapon_style()

	if event.is_action_pressed("weapon_previous"):
		_equip_previous_weapon_style()
	
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
	if combat_controller != null and not combat_controller.allows_rotation():
		return
	
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
	
	_sync_locomotion_velocity_after_slide()
	
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

	var local_move := Vector3(input_vector.x, 0.0, input_vector.y)

	if local_move.length() > 1.0:
		local_move = local_move.normalized()

	# Animation convention:
	# Input.get_vector gives forward as negative Y.
	# Animation blend uses forward as positive Y.
	current_local_movement_input = Vector2(input_vector.x, -input_vector.y)

	var target_speed := jog_speed
	current_locomotion_blend_value = jog_blend_value

	var walk_held := Input.is_action_pressed("walk")

	if walk_held:
		target_speed = walk_speed
		current_locomotion_blend_value = walk_blend_value

	elif sprint_enabled:
		target_speed = run_speed
		current_locomotion_blend_value = run_blend_value

	is_sprinting = (
		sprint_enabled
		and not walk_held
		and input_vector.length() > 0.0
		and movement_state == MovementState.GROUNDED
		and is_on_floor()
	)

	if input_vector.length() <= 0.0:
		current_locomotion_blend_value = 0.0

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
	
	var movement_lock: float = 1 - combat_controller.get_current_movement_lock_strength()
	current_locomotion_blend_value *= movement_lock
	current_locomotion_blend_value -= combat_controller.attack_motion_velocity.z/run_speed

	var world_move := movement_basis * local_move
	var desired_input_velocity := world_move * target_speed * movement_lock

	_apply_horizontal_locomotion_velocity(desired_input_velocity, input_vector.length(), delta)
	_apply_attack_motion_velocity(movement_basis, delta)
	_apply_gravity(delta)
	
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

func _enable_sprint() -> void:
	sprint_enabled = true
	print("Sprint enabled: ", sprint_enabled)
	
func _disable_sprint() -> void:
	sprint_enabled = false
	print("Sprint enabled: ", sprint_enabled)
		
func _try_main_attack() -> void:
	if combat_controller == null:
		return

	combat_controller.receive_basic_input(_can_start_sprint_attack())

func _can_start_sprint_attack() -> bool:
	if not sprint_enabled:
		return false

	if movement_state != MovementState.GROUNDED:
		return false

	if not is_on_floor():
		return false

	return locomotion_velocity.length() >= sprint_attack_min_speed

func _try_strong_attack() -> void:
	if combat_controller == null:
		return

	combat_controller.receive_strong_input()

func _get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)

func _set_horizontal_velocity(horizontal_velocity: Vector3) -> void:
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	
func _apply_horizontal_locomotion_velocity(
	desired_input_velocity: Vector3,
	input_strength: float,
	delta: float
) -> void:
	var accel := ground_acceleration
	var decel := ground_deceleration

	if not is_on_floor():
		accel = air_acceleration
		decel = air_deceleration

	if movement_state == MovementState.LANDING:
		accel = landing_acceleration
		decel = landing_acceleration

	var rate := accel

	if input_strength <= 0.0:
		rate = decel

	if rate > 0.0:
		locomotion_velocity = locomotion_velocity.move_toward(
			desired_input_velocity,
			rate * delta
		)

	velocity.x = locomotion_velocity.x
	velocity.z = locomotion_velocity.z
	
func _apply_attack_motion_velocity(movement_basis: Basis, _delta: float) -> void:
	if combat_controller == null:
		return

	if not combat_controller.is_attacking():
		return

	var local_attack_velocity := combat_controller.get_attack_motion_velocity()

	if local_attack_velocity.length_squared() <= 0.0001:
		return

	var attack_world_velocity := movement_basis * local_attack_velocity

	velocity.x = locomotion_velocity.x + attack_world_velocity.x
	velocity.z = locomotion_velocity.z + attack_world_velocity.z
	
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
			
func _sync_locomotion_velocity_after_slide() -> void:
	if combat_controller != null and combat_controller.is_attacking():
		return

	locomotion_velocity.x = velocity.x
	locomotion_velocity.z = velocity.z

func _begin_strong_attack() -> void:
	if combat_controller == null:
		return

	combat_controller.begin_strong_input(_can_start_sprint_attack())

func _release_strong_attack() -> void:
	if combat_controller == null:
		return

	combat_controller.release_strong_input()

func _equip_weapon_style_index(index: int) -> void:
	if weapon_loadout_controller == null:
		return

	weapon_loadout_controller.equip_style_by_index(index)


func _equip_next_weapon_style() -> void:
	if weapon_loadout_controller == null:
		return

	weapon_loadout_controller.equip_next_style()


func _equip_previous_weapon_style() -> void:
	if weapon_loadout_controller == null:
		return

	weapon_loadout_controller.equip_previous_style()
	
