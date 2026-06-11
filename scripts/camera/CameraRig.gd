class_name CameraRig
extends Node3D

@export var target: Node3D
@export var follow_speed: float = 18.0
@export var mouse_sensitivity = 0.003
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 20.0
@export var target_height: float = 1.4

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot

var yaw: float = 0.0
var pitch: float = deg_to_rad(-15.0)

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
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		
		var min_pitch := deg_to_rad(min_pitch_degrees)
		var max_pitch := deg_to_rad(max_pitch_degrees)
		pitch = clamp(pitch, min_pitch, max_pitch)
		
		yaw_pivot.rotation.y = yaw
		pitch_pivot.rotation.x = pitch
		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_flat_camera_basis() -> Basis:
	var forward := -yaw_pivot.global_transform.basis.z
	var right := yaw_pivot.global_transform.basis.x
	
	forward.y = 0.0
	right.y = 0.0
	
	forward = forward.normalized()
	right = right.normalized()
	
	var basis := Basis()
	basis.x = right
	basis.y = Vector3.UP
	basis.z = -forward
	return basis
	
func _get_target_position() -> Vector3:
	if target == null:
		return global_position
	
	return target.global_position + Vector3.UP * target_height
	
