class_name WeaponTraceData
extends Resource

enum TraceMode {
	HORIZONTAL_ARC,
	VERTICAL_ARC,
	THRUST,
	LINEAR,
}

@export_group("Timing")
@export var start_time: float = 0.18
@export var end_time: float = 0.36
@export_range(1, 24, 1) var sample_count: int = 6

@export_group("Trace Mode")
@export var trace_mode: TraceMode = TraceMode.HORIZONTAL_ARC

@export_group("Arc Shape")
@export var inner_radius: float = 0.35
@export var outer_radius: float = 1.35
@export var height: float = 1.1
@export var vertical_thickness: float = 0.45	# Horizontal-arc vertical band thickness.
@export var blade_thickness: float = 0.25		# Arc-band thickness perpendicular to blade length.

@export_group("Horizontal Arc")
@export var start_angle_degrees: float = 55.0
@export var end_angle_degrees: float = -55.0

@export_group("Vertical Arc")
@export var vertical_arc_forward_offset: float = -0.85
@export var vertical_arc_start_height: float = 1.75
@export var vertical_arc_end_height: float = 0.65
@export var vertical_arc_start_x: float = 0.0
@export var vertical_arc_end_x: float = 0.0
@export var vertical_arc_depth_radius: float = 0.35

@export_group("Linear / Thrust")
@export var start_position: Vector3 = Vector3(0.0, 1.1, -0.45)
@export var end_position: Vector3 = Vector3(0.0, 1.1, -1.65)
@export var trace_width: float = 0.35				#size of thrust/linear attack cross-section
@export var trace_height: float = 0.35

@export_group("Path Rotation")
@export var local_position: Vector3 = Vector3.ZERO
@export var local_rotation_degrees: Vector3 = Vector3.ZERO

@export_group("Debug")
@export var debug_visible: bool = true
@export var debug_linger_time: float = 0.15
