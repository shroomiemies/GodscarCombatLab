class_name CombatController
extends Node

enum CombatState {
	IDLE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

enum BufferedComboInput {
	NONE,
	BASIC,
	STRONG,
}

signal attack_started(attack_data: AttackData)
signal attack_phase_changed(new_state: CombatState)
signal attack_finished()
signal attack_hit(hit_result: HitResult)

@export var default_attack: AttackData
@export var hitbox_emitter: HitboxEmitter
@export var default_strong_attack: AttackData

var combat_state: CombatState = CombatState.IDLE
var current_attack: AttackData
var attack_time: float = 0.0
var attack_motion_velocity: Vector3 = Vector3.ZERO
var buffered_combo_input: BufferedComboInput = BufferedComboInput.NONE
var has_chained_this_attack: bool = false
var strong_input_held: bool = false
var strong_release_requested: bool = false
var strong_charge_time: float = 0.0
var stored_strong_charge_time: float = 0.0
var current_attack_charge_fraction: float = 0.0
var current_main_hand_trace_origin_offset: Vector3 = Vector3(0.28, 0.0, 0.0)
var current_off_hand_trace_origin_offset: Vector3 = Vector3(-0.28, 0.0, 0.0)
var sprint_basic_attack: AttackData
var sprint_strong_attack: AttackData
var held_strong_entry_attack: AttackData

func _ready() -> void:
	if hitbox_emitter != null:
		hitbox_emitter.hurtbox_hit.connect(_on_hurtbox_hit)

func _physics_process(delta: float) -> void:
	_update_strong_charge(delta)

	attack_motion_velocity = Vector3.ZERO

	if combat_state == CombatState.IDLE:
		_clear_hitboxes()
		return

	attack_time += delta
	_update_attack_phase()
	_try_chain_buffered_combo()
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
	return try_start_attack_with_charge(attack_data, 0.0)

func try_start_attack_with_charge(attack_data: AttackData, charge_fraction: float) -> bool:
	if attack_data == null:
		return false

	if not can_start_attack():
		return false

	_start_attack_internal(attack_data, charge_fraction)
	return true

func _start_attack_internal(attack_data: AttackData, charge_fraction: float) -> void:
	current_attack = attack_data
	attack_time = 0.0
	combat_state = CombatState.STARTUP
	buffered_combo_input = BufferedComboInput.NONE
	has_chained_this_attack = false
	current_attack_charge_fraction = clamp(charge_fraction, 0.0, 1.0)
	strong_release_requested = false

	if hitbox_emitter != null:
		hitbox_emitter.begin_attack_trace()

	print(
		"Attack started: ",
		current_attack.attack_id,
		" charge ",
		str(roundi(current_attack_charge_fraction * 100.0)),
		"%"
	)

	attack_started.emit(current_attack)
	attack_phase_changed.emit(combat_state)

func _update_attack_phase() -> void:
	if current_attack == null:
		_finish_attack()
		return

	var startup_end := current_attack.startup_duration
	var active_end := startup_end + current_attack.active_duration
	var recovery_end := active_end + current_attack.recovery_duration

	if attack_time >= recovery_end:
		if _is_waiting_for_strong_release():
			_set_combat_state(CombatState.RECOVERY)

			var timeout_time := _get_strong_hold_timeout_time()

			if (
				current_attack.strong_combo_auto_release_on_timeout
				and attack_time >= timeout_time
			):
				stored_strong_charge_time = max(stored_strong_charge_time, strong_charge_time)
				strong_input_held = false
				strong_release_requested = true

			return

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

	hitbox_emitter.show_attack_debug(current_attack,attack_time,current_attack_charge_fraction)

func _clear_hitboxes() -> void:
	if hitbox_emitter == null:
		return

	hitbox_emitter.clear_debug_hitboxes()

func _on_hurtbox_hit(hit_result: HitResult) -> void:
	print("CombatController received hit on: ", hit_result.actor.name)
	attack_hit.emit(hit_result)

func receive_basic_input(use_sprint_entry: bool = false) -> void:
	if combat_state == CombatState.IDLE:
		var entry_attack := _get_basic_entry_attack(use_sprint_entry)

		if entry_attack == null:
			push_warning("CombatController has no basic entry attack assigned.")
			return

		try_start_attack(entry_attack)
		return

	_try_buffer_combo_input(BufferedComboInput.BASIC)
	_try_chain_buffered_combo()

func _get_basic_entry_attack(use_sprint_entry: bool) -> AttackData:
	if use_sprint_entry and sprint_basic_attack != null:
		return sprint_basic_attack

	return default_attack

func _try_chain_buffered_combo() -> void:
	if current_attack == null:
		return

	if has_chained_this_attack:
		return

	if not _has_buffered_combo_input():
		return

	var input_to_chain := buffered_combo_input
	var required_chain_time := _get_chain_time_for_input(input_to_chain)

	if attack_time < required_chain_time:
		return

	var followup := _get_followup_for_input(input_to_chain)

	if followup == null:
		buffered_combo_input = BufferedComboInput.NONE
		return

	if followup == current_attack and not current_attack.allow_self_chain:
		buffered_combo_input = BufferedComboInput.NONE
		return

	if input_to_chain == BufferedComboInput.STRONG:
		if not strong_release_requested:
			if strong_input_held:
				var timeout_time := _get_strong_hold_timeout_time()

				if (
					current_attack.strong_combo_auto_release_on_timeout
					and attack_time >= timeout_time
				):
					stored_strong_charge_time = max(stored_strong_charge_time, strong_charge_time)
					strong_input_held = false
					strong_release_requested = true
				else:
					return
			else:
				return

	var charge_fraction := 0.0

	if input_to_chain == BufferedComboInput.STRONG:
		charge_fraction = _get_buffered_strong_charge_fraction(followup)

	has_chained_this_attack = true

	print(
		"Combo chain: ",
		current_attack.attack_id,
		" -> ",
		followup.attack_id,
		" charge ",
		str(roundi(charge_fraction * 100.0)),
		"%"
	)

	_start_chained_attack(followup, charge_fraction)

	if input_to_chain == BufferedComboInput.STRONG:
		_clear_strong_charge_state()

func _try_buffer_combo_input(combo_input: BufferedComboInput) -> void:
	if current_attack == null:
		return

	if not _is_combo_input_window_open():
		return

	var followup := _get_followup_for_input(combo_input)

	if followup == null:
		return

	buffered_combo_input = combo_input

	print("Buffered combo input: ", BufferedComboInput.keys()[combo_input])
	
func _is_combo_input_window_open() -> bool:
	#placeholder
	return current_attack != null 

func _get_followup_for_input(combo_input: BufferedComboInput) -> AttackData:
	if current_attack == null:
		return null

	match combo_input:
		BufferedComboInput.BASIC:
			if current_attack.basic_followup != null:
				return current_attack.basic_followup

			if current_attack.basic_loops_to_default:
				return default_attack

			return null

		BufferedComboInput.STRONG:
			return current_attack.strong_followup
		_:
			return null

func _has_buffered_combo_input() -> bool:
	return buffered_combo_input != BufferedComboInput.NONE
	
func _start_chained_attack(next_attack: AttackData, charge_fraction: float = 0.0) -> void:
	_start_attack_internal(next_attack, charge_fraction)
	
func _clear_stale_combo_buffer() -> void:
	if current_attack == null:
		buffered_combo_input = BufferedComboInput.NONE
		return

	if attack_time > current_attack.combo_input_close_time:
		if buffered_combo_input != BufferedComboInput.NONE:
			print("Combo buffer expired.")
		buffered_combo_input = BufferedComboInput.NONE

func _update_strong_charge(delta: float) -> void:
	if not strong_input_held:
		return

	strong_charge_time += delta
	stored_strong_charge_time = max(stored_strong_charge_time, strong_charge_time)

func _get_chain_time_for_input(combo_input: BufferedComboInput) -> float:
	if current_attack == null:
		return 0.0

	if combo_input == BufferedComboInput.STRONG:
		if current_attack.strong_combo_chain_time >= 0.0:
			return current_attack.strong_combo_chain_time

	return current_attack.combo_chain_time

func _get_charge_fraction_for_attack(attack_data: AttackData, charge_time: float) -> float:
	if attack_data == null:
		return 0.0

	if not attack_data.can_charge:
		return 0.0

	if attack_data.max_charge_time <= 0.0:
		return 0.0

	if charge_time < attack_data.min_charge_time:
		return 0.0

	return clamp(charge_time / attack_data.max_charge_time, 0.0, 1.0)

func _get_buffered_strong_charge_fraction(next_attack: AttackData) -> float:
	var charge_time := stored_strong_charge_time

	if strong_input_held:
		charge_time = max(charge_time, strong_charge_time)

	return _get_charge_fraction_for_attack(next_attack, charge_time)
	
func begin_strong_input(use_sprint_entry: bool = false) -> void:
	strong_input_held = true
	strong_release_requested = false
	strong_charge_time = 0.0
	stored_strong_charge_time = 0.0

	if combat_state == CombatState.IDLE:
		held_strong_entry_attack = _get_strong_entry_attack(use_sprint_entry)
		return

	_try_buffer_combo_input(BufferedComboInput.STRONG)
	
func _get_strong_entry_attack(use_sprint_entry: bool) -> AttackData:
	if use_sprint_entry and sprint_strong_attack != null:
		return sprint_strong_attack

	return default_strong_attack
		
func release_strong_input() -> void:
	if not strong_input_held:
		return

	stored_strong_charge_time = max(stored_strong_charge_time, strong_charge_time)
	strong_input_held = false

	if combat_state == CombatState.IDLE:
		var entry_attack := held_strong_entry_attack

		if entry_attack == null:
			push_warning("CombatController has no strong entry attack assigned.")
			_clear_strong_charge_state()
			return

		var charge_fraction := _get_charge_fraction_for_attack(
			entry_attack,
			stored_strong_charge_time
		)

		try_start_attack_with_charge(entry_attack, charge_fraction)
		_clear_strong_charge_state()
		return

	if buffered_combo_input == BufferedComboInput.STRONG:
		strong_release_requested = true
		_try_chain_buffered_combo()
	else:
		_clear_strong_charge_state()
		
func _clear_strong_charge_state() -> void:
	strong_input_held = false
	strong_release_requested = false
	strong_charge_time = 0.0
	stored_strong_charge_time = 0.0	
	held_strong_entry_attack = null

func _get_current_attack_end_time() -> float:
	if current_attack == null:
		return 0.0

	return (
		current_attack.startup_duration
		+ current_attack.active_duration
		+ current_attack.recovery_duration
	)

func _get_strong_hold_timeout_time() -> float:
	if current_attack == null:
		return 0.0

	return _get_current_attack_end_time() + current_attack.strong_combo_max_hold_extension

func _is_waiting_for_strong_release() -> bool:
	return (
		current_attack != null
		and buffered_combo_input == BufferedComboInput.STRONG
		and current_attack.strong_followup != null
		and strong_input_held
	)

func equip_weapon_style(style_data: WeaponStyleData) -> void:
	if style_data == null:
		push_warning("Tried to equip null WeaponStyleData.")
		return

	default_attack = style_data.default_basic_attack
	default_strong_attack = style_data.default_strong_attack
	sprint_basic_attack = style_data.sprint_basic_attack
	sprint_strong_attack = style_data.sprint_strong_attack

	current_main_hand_trace_origin_offset = style_data.main_hand_trace_origin_offset
	current_off_hand_trace_origin_offset = style_data.off_hand_trace_origin_offset

	if hitbox_emitter != null:
		hitbox_emitter.trace_origin_offset = current_main_hand_trace_origin_offset

	print("Equipped weapon style: ", style_data.display_name)

	if default_attack == null:
		push_warning("Weapon style has no default_basic_attack: " + str(style_data.style_id))

	if default_strong_attack == null:
		push_warning("Weapon style has no default_strong_attack: " + str(style_data.style_id))
