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

@export_group("Hit Volumes")
@export var hit_volumes: Array[HitVolumeData] = []

@export_group("Weapon Traces")
@export var weapon_traces: Array[WeaponTraceData] = []

@export_group("Combo")
@export var basic_followup: AttackData
@export var basic_loops_to_default: bool = false
@export var strong_followup: AttackData
@export var combo_chain_time: float = 0.65
@export var allow_self_chain: bool = false
@export var strong_combo_chain_time: float = -1.0  	#Use combo_chain_time unless this attack defines a special strong-chain time.
@export var strong_combo_max_hold_extension: float = 1.0
@export var strong_combo_auto_release_on_timeout: bool = true

@export_group("Charge")
@export var can_charge: bool = false
@export var min_charge_time: float = 0.0
@export var max_charge_time: float = 0.45
@export var charge_power_bonus: float = 0.25
