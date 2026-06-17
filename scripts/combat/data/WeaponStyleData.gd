class_name WeaponStyleData
extends Resource

@export var style_id: StringName = &"unnamed_style"
@export var display_name: String = "Unnamed Style"

@export_group("Default Attacks")
@export var default_basic_attack: AttackData
@export var default_strong_attack: AttackData

@export_group("Debug")
@export var debug_description: String = ""
