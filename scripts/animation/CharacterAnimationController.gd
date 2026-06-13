class_name CharacterAnimationController
extends Node

@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree

@export var locomotion_blend_path: String = "parameters/Grounded/blend_position"
@export var state_machine_playback_path: String = "parameters/playback"

@export var idle_animation_name: StringName = &"Idle/mixamo_com"

@export var walk_forward_animation_name: StringName = &"Walking/mixamo_com"
@export var walk_back_animation_name: StringName = &"Walking Backwards/mixamo_com"
@export var walk_left_animation_name: StringName = &"Left Strafe Walking/mixamo_com"
@export var walk_right_animation_name: StringName = &"Right Strafe Walking/mixamo_com"

@export var jog_forward_animation_name: StringName = &"Jog Forward/mixamo_com"
@export var jog_back_animation_name: StringName = &"Jog Backward/mixamo_com"
@export var jog_left_animation_name: StringName = &"Jog Strafe Left/mixamo_com"
@export var jog_right_animation_name: StringName = &"Jog Strafe Right/mixamo_com"

@export var jog_forward_left_animation_name: StringName = &"Jog FL/mixamo_com"
@export var jog_forward_right_animation_name: StringName = &"Jog FR/mixamo_com"
@export var jog_back_left_animation_name: StringName = &"Jog BL/mixamo_com"
@export var jog_back_right_animation_name: StringName = &"Jog BR/mixamo_com"

@export var run_forward_animation_name: StringName = &"Running/mixamo_com"
@export var run_back_animation_name: StringName = &"Running Backward/mixamo_com"
@export var run_left_animation_name: StringName = &"Left Strafe/mixamo_com"
@export var run_right_animation_name: StringName = &"Right Strafe/mixamo_com"

@export var jump_start_animation_name: StringName = &"Jumping Up/mixamo_com"
@export var fall_animation_name: StringName = &"Falling Idle/mixamo_com"
@export var land_animation_name: StringName = &"Jumping Down/mixamo_com"

@export var blend_smoothing: float = 14.0

var current_locomotion_blend: Vector2 = Vector2.ZERO
var target_locomotion_blend: Vector2 = Vector2.ZERO

var playback: AnimationNodeStateMachinePlayback


func _ready() -> void:
	_configure_animation_loops()

	if animation_tree != null:
		animation_tree.active = true
		animation_tree.set(locomotion_blend_path, Vector2.ZERO)
		playback = animation_tree.get(state_machine_playback_path) as AnimationNodeStateMachinePlayback
		travel_grounded()


func _process(delta: float) -> void:
	_update_locomotion_blend(delta)


func set_locomotion_input(local_movement: Vector2, speed_blend_value: float) -> void:
	if local_movement.length() > 1.0:
		local_movement = local_movement.normalized()

	speed_blend_value = clamp(speed_blend_value, 0.0, 1.0)
	target_locomotion_blend = local_movement * speed_blend_value

func travel_grounded() -> void:
	_travel_to(&"Grounded")

func travel_jump_start() -> void:
	_travel_to(&"JumpStart")

func travel_fall() -> void:
	_travel_to(&"Fall")

func travel_land() -> void:
	_travel_to(&"Land")

func _travel_to(state_name: StringName) -> void:
	if playback == null:
		return

	if playback.get_current_node() == state_name:
		return

	playback.travel(state_name)

func _update_locomotion_blend(delta: float) -> void:
	if animation_tree == null:
		return

	current_locomotion_blend = current_locomotion_blend.lerp(
		target_locomotion_blend,
		1.0 - exp(-blend_smoothing * delta)
	)

	animation_tree.set(locomotion_blend_path, current_locomotion_blend)

func _configure_animation_loops() -> void:
	if animation_player == null:
		push_warning("CharacterAnimationController has no AnimationPlayer assigned.")
		return

	var looping_animations: Array[StringName] = [
		idle_animation_name,

		walk_forward_animation_name,
		walk_back_animation_name,
		walk_left_animation_name,
		walk_right_animation_name,

		jog_forward_animation_name,
		jog_back_animation_name,
		jog_left_animation_name,
		jog_right_animation_name,

		jog_forward_left_animation_name,
		jog_forward_right_animation_name,
		jog_back_left_animation_name,
		jog_back_right_animation_name,

		run_forward_animation_name,
		run_back_animation_name,
		run_left_animation_name,
		run_right_animation_name,

		fall_animation_name,
	]

	var non_looping_animations: Array[StringName] = [
		jump_start_animation_name,
		land_animation_name,
	]

	for animation_name in looping_animations:
		_set_animation_looping(animation_name, true)

	for animation_name in non_looping_animations:
		_set_animation_looping(animation_name, false)

func _set_animation_looping(animation_name: StringName, should_loop: bool) -> void:
	if animation_player == null:
		return

	if not animation_player.has_animation(animation_name):
		push_warning("Cannot set looping. AnimationPlayer does not have animation: %s" % animation_name)
		return

	var animation := animation_player.get_animation(animation_name)

	if animation == null:
		return

	if should_loop:
		animation.loop_mode = Animation.LOOP_LINEAR
	else:
		animation.loop_mode = Animation.LOOP_NONE
