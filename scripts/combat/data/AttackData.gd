class_name AttackData
extends Resource

@export var attack_id: StringName = &"unnamed_attack"

@export_group("Timing")
@export var total_duration: float = 0.75
@export var startup_duration: float = 0.18
@export var active_duration: float = 0.16
@export var recovery_duration: float = 0.41

@export_group("Movement")
@export var movement_lock_strength: float = 1.0
@export var local_displacement: Vector3 = Vector3.ZERO
@export var displacement_start_time: float = 0.0
@export var displacement_end_time: float = 0.75
@export var allow_rotation_during_startup: bool = true
@export var allow_rotation_during_active: bool = false
@export var allow_rotation_during_recovery: bool = true
@export var max_displacement_speed: float = 8.0

@export_group("Animation")
@export var animation_name: StringName = &""
