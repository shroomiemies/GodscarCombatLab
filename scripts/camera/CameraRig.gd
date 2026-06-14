class_name CameraRig
extends Node3D

@export var target: Node3D
@export var follow_speed: float = 18.0
@export var mouse_sensitivity = 0.003
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 20.0
@export var target_height: float = 1.4
@export var lock_on_yaw_speed: float = 14.0
@export var lock_on_pitch_degrees: float = -12.0
@export var lock_on_target_height: float = 1.2

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot

var yaw: float = 0.0
var pitch: float = deg_to_rad(-15.0)
var lock_on_target: Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if target != null:
		global_position = _get_target_position()
	
	yaw_pivot.rotation.y = yaw
	pitch_pivot.rotation.x = pitch

func _process(delta: float) -> void:
	if target == null:
		return
		
	global_position = global_position.lerp(_get_target_position(), 1.0 - exp(-follow_speed * delta))
	
	if is_locked_on():
		_update_lock_on_rotation(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_locked_on():
			# While locked on, ignore horizontal mouse look.
			# Allow vertical camera adjustment if desired.
			pitch -= event.relative.y * mouse_sensitivity
		else:
			yaw -= event.relative.x * mouse_sensitivity
			pitch -= event.relative.y * mouse_sensitivity

		var min_pitch := deg_to_rad(min_pitch_degrees)
		var max_pitch := deg_to_rad(max_pitch_degrees)
		pitch = clamp(pitch, min_pitch, max_pitch)

		yaw_pivot.rotation.y = yaw
		pitch_pivot.rotation.x = pitch
		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func get_flat_camera_basis() -> Basis:
	var forward := -yaw_pivot.global_transform.basis.z
	var right := yaw_pivot.global_transform.basis.x
	
	forward.y = 0.0
	right.y = 0.0
	
	forward = forward.normalized()
	right = right.normalized()
	
	var camera_basis := Basis()
	camera_basis.x = right
	camera_basis.y = Vector3.UP
	camera_basis.z = -forward
	return camera_basis
	
func _get_target_position() -> Vector3:
	if target == null:
		return global_position
	
	return target.global_position + Vector3.UP * target_height
	
func set_lock_on_target(new_target: Node3D) -> void:
	lock_on_target = new_target


func clear_lock_on_target() -> void:
	lock_on_target = null


func is_locked_on() -> bool:
	return lock_on_target != null and is_instance_valid(lock_on_target)


func get_lock_on_target_point() -> Vector3:
	if not is_locked_on():
		return global_position

	if lock_on_target.has_method("get_target_point"):
		return lock_on_target.get_target_point()

	return lock_on_target.global_position + Vector3.UP * lock_on_target_height
	
func _update_lock_on_rotation(delta: float) -> void:
	var target_point := get_lock_on_target_point()
	var to_target := target_point - global_position
	to_target.y = 0.0

	if to_target.length_squared() < 0.0001:
		return

	to_target = to_target.normalized()

	var target_yaw := atan2(-to_target.x, -to_target.z)
	yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-lock_on_yaw_speed * delta))

	pitch = lerp(
		pitch,
		deg_to_rad(lock_on_pitch_degrees),
		1.0 - exp(-lock_on_yaw_speed * delta)
	)

	yaw_pivot.rotation.y = yaw
	pitch_pivot.rotation.x = pitch
