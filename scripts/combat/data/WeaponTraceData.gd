class_name WeaponTraceData
extends Resource

@export_group("Timing")
@export var start_time: float = 0.18
@export var end_time: float = 0.36
@export_range(1, 16, 1) var sample_count: int = 6

@export_group("Arc Shape")
@export var inner_radius: float = 0.35
@export var outer_radius: float = 1.35
@export var height: float = 1.1
@export var vertical_thickness: float = 0.45

@export_group("Arc Angles")
@export var start_angle_degrees: float = 55.0
@export var end_angle_degrees: float = -55.0

@export_group("Local Transform")
@export var local_position: Vector3 = Vector3.ZERO
@export var local_rotation_degrees: Vector3 = Vector3.ZERO

@export_group("Debug")
@export var debug_visible: bool = true
@export var debug_linger_time: float = 0.15
