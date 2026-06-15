class_name HitVolumeData
extends Resource

enum ShapeType {
	BOX,
	SPHERE,
	CAPSULE,
}

@export var shape_type: ShapeType = ShapeType.BOX

@export_group("Timing")
@export var start_time: float = 0.18
@export var end_time: float = 0.34

@export_group("Transform")
@export var local_position: Vector3 = Vector3(0.0, 1.0, -1.0)
@export var local_rotation_degrees: Vector3 = Vector3.ZERO

@export_group("Shape Size")
@export var box_size: Vector3 = Vector3(1.0, 1.0, 1.0)
@export var sphere_radius: float = 0.5
@export var capsule_radius: float = 0.35
@export var capsule_height: float = 1.2

@export_group("Debug")
@export var debug_visible: bool = true
