class_name DebugStateLabel
extends Label

@export var player: Player


func refresh() -> void:
	text = _build_debug_text()


func _build_debug_text() -> String:
	if player == null:
		return "GODSCAR COMBAT LAB DEBUG\nPlayer: unassigned"

	var lines: PackedStringArray = []

	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	var locomotion_speed := player.locomotion_velocity.length()

	var frame_speed := 0.0
	if player.movement_frame != null:
		frame_speed = player.movement_frame.linear_velocity.length()

	var style_name := "None"
	if player.weapon_loadout_controller != null:
		var style_data := player.weapon_loadout_controller.get_current_style()
		if style_data != null:
			style_name = style_data.display_name

	var lock_target_name := "None"
	if player.targeting_controller != null and player.targeting_controller.has_target():
		var target := player.targeting_controller.current_target
		if target != null:
			lock_target_name = target.name
		else:
			lock_target_name = "Invalid target"

	lines.append("GODSCAR COMBAT LAB DEBUG")
	lines.append("")
	lines.append("Style: %s" % style_name)
	lines.append("Movement: %s | Grounded: %s" % [
		_enum_name(Player.MovementState, player.movement_state),
		_bool_text(player.is_on_floor())
	])
	lines.append("Speed: %.2f | Locomotion: %.2f | Frame: %.2f" % [
		horizontal_speed,
		locomotion_speed,
		frame_speed
	])
	lines.append("Sprint Mode: %s | Active: %s" % [
		_bool_text(player.sprint_enabled),
		_bool_text(player.is_sprinting)
	])
	lines.append("Lock Target: %s" % lock_target_name)
	lines.append("")

	if player.combat_controller == null:
		lines.append("Combat Controller: missing")
		return "\n".join(lines)

	var combat := player.combat_controller
	var attack_name := "None"
	var attack_time := 0.0
	var attack_duration := 0.0

	if combat.current_attack != null:
		attack_name = str(combat.current_attack.attack_id)
		attack_time = combat.attack_time
		attack_duration = (
			combat.current_attack.startup_duration
			+ combat.current_attack.active_duration
			+ combat.current_attack.recovery_duration
		)

	var hit_count := 0
	if combat.hitbox_emitter != null:
		hit_count = combat.hitbox_emitter.get_hit_count_this_attack()

	lines.append("Combat: %s | Rotation: %s" % [
		_enum_name(CombatController.CombatState, combat.combat_state),
		_bool_text(combat.allows_rotation())
	])
	lines.append("Attack: %s" % attack_name)
	lines.append("Attack Time: %.3f / %.3f" % [
		attack_time,
		attack_duration
	])
	lines.append("Buffered Input: %s | Hits: %d" % [
		_enum_name(
			CombatController.BufferedComboInput,
			combat.buffered_combo_input
		),
		hit_count
	])
	lines.append("Strong Held: %s | Hold Time: %.2f s" % [
		_bool_text(combat.strong_input_held),
		combat.strong_charge_time
	])
	lines.append("Attack Charge: %d%%" % roundi(
		combat.current_attack_charge_fraction * 100.0
	))

	return "\n".join(lines)


func _enum_name(enum_values: Dictionary, value: int) -> String:
	for key in enum_values:
		if int(enum_values[key]) == value:
			return str(key)

	return "UNKNOWN (%d)" % value


func _bool_text(value: bool) -> String:
	return "YES" if value else "NO"
