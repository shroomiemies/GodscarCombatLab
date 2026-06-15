class_name CombatController
extends Node

enum CombatState {
	IDLE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

signal attack_started(attack_data: AttackData)
signal attack_phase_changed(new_state: CombatState)
signal attack_finished()

@export var default_attack: AttackData
@export var hitbox_emitter: HitboxEmitter

var combat_state: CombatState = CombatState.IDLE
var current_attack: AttackData
var attack_time: float = 0.0
var attack_motion_velocity: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	attack_motion_velocity = Vector3.ZERO
	
	if combat_state == CombatState.IDLE:
		return

	attack_time += delta
	_update_attack_phase()
	_update_attack_motion_velocity(delta)
	_update_hitboxes()

func can_start_attack() -> bool:
	return combat_state == CombatState.IDLE

func try_start_default_attack() -> bool:
	if default_attack == null:
		push_warning("CombatController has no default_attack assigned.")
		return false

	return try_start_attack(default_attack)

func try_start_attack(attack_data: AttackData) -> bool:
	if attack_data == null:
		return false

	if not can_start_attack():
		return false

	current_attack = attack_data
	attack_time = 0.0
	combat_state = CombatState.STARTUP
	
	if hitbox_emitter != null:
		hitbox_emitter.begin_attack_trace()

	print("Attack started: ", current_attack.attack_id)
	attack_started.emit(current_attack)
	attack_phase_changed.emit(combat_state)

	return true

func _update_attack_phase() -> void:
	if current_attack == null:
		_finish_attack()
		return

	var startup_end := current_attack.startup_duration
	var active_end := startup_end + current_attack.active_duration
	var recovery_end := active_end + current_attack.recovery_duration

	if attack_time >= recovery_end:
		_finish_attack()
		return

	if attack_time >= active_end:
		_set_combat_state(CombatState.RECOVERY)
	elif attack_time >= startup_end:
		_set_combat_state(CombatState.ACTIVE)
	else:
		_set_combat_state(CombatState.STARTUP)

func _set_combat_state(new_state: CombatState) -> void:
	if combat_state == new_state:
		return

	combat_state = new_state

	match combat_state:
		CombatState.STARTUP:
			print("Attack phase: STARTUP")
		CombatState.ACTIVE:
			print("Attack phase: ACTIVE")
		CombatState.RECOVERY:
			print("Attack phase: RECOVERY")
		CombatState.IDLE:
			print("Attack phase: IDLE")

	attack_phase_changed.emit(combat_state)

func _finish_attack() -> void:
	print("Attack finished.")

	combat_state = CombatState.IDLE
	current_attack = null
	attack_time = 0.0

	_clear_hitboxes()
	attack_finished.emit()

func is_attacking() -> bool:
	return combat_state != CombatState.IDLE

func get_current_movement_lock_strength() -> float:
	if current_attack == null:
		return 0.0

	if combat_state == CombatState.IDLE:
		return 0.0

	return current_attack.movement_lock_strength

func allows_rotation() -> bool:
	if current_attack == null:
		return true

	match combat_state:
		CombatState.STARTUP:
			return current_attack.allow_rotation_during_startup
		CombatState.ACTIVE:
			return current_attack.allow_rotation_during_active
		CombatState.RECOVERY:
			return current_attack.allow_rotation_during_recovery
		_:
			return true

func _update_attack_motion_velocity(delta: float) -> void:
	if current_attack == null:
		attack_motion_velocity = Vector3.ZERO
		return

	if delta <= 0.0:
		attack_motion_velocity = Vector3.ZERO
		return

	var start_time := current_attack.displacement_start_time
	var end_time := current_attack.displacement_end_time

	if end_time <= start_time:
		attack_motion_velocity = Vector3.ZERO
		return

	if attack_time < start_time or attack_time > end_time:
		attack_motion_velocity = Vector3.ZERO
		return

	var displacement_duration := end_time - start_time
	attack_motion_velocity = current_attack.local_displacement / displacement_duration
	
	
	if attack_motion_velocity.length() > current_attack.max_displacement_speed:
		attack_motion_velocity = attack_motion_velocity.normalized() * current_attack.max_displacement_speed
	
func get_attack_motion_velocity() -> Vector3:
	return attack_motion_velocity
	
func _update_hitboxes() -> void:
	if hitbox_emitter == null:
		return

	hitbox_emitter.show_attack_debug(current_attack, attack_time)

func _clear_hitboxes() -> void:
	if hitbox_emitter == null:
		return

	hitbox_emitter.clear_debug_hitboxes()
