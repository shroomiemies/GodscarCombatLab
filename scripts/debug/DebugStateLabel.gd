class_name DebugStateLabel
extends Label

@export var player: Player

func _process(_delta: float) -> void:
	if player == null:
		text = "No player assigned"
		return

	var movement_state_text := "Movement: " + str(player.movement_state)

	var combat_state_text := "Combat: None"
	if player.combat_controller != null:
		combat_state_text = "Combat: " + str(player.combat_controller.combat_state)

	text = movement_state_text + "\n" + combat_state_text
