class_name WeaponStyleData
extends Resource

@export var style_id: StringName = &"unnamed_style"
@export var display_name: String = "Unnamed Style"

@export_group("Default Attacks")
@export var default_basic_attack: AttackData
@export var default_strong_attack: AttackData

@export_group("Sprint Entry Attacks")
@export var sprint_basic_attack: AttackData
@export var sprint_strong_attack: AttackData

@export_group("Trace Origin")
@export var main_hand_trace_origin_offset: Vector3 = Vector3(0.28, 0.0, 0.0)
@export var off_hand_trace_origin_offset: Vector3 = Vector3(-0.28, 0.0, 0.0)

@export_group("Debug")
@export var debug_description: String = ""
