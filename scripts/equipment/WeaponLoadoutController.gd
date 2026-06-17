class_name WeaponLoadoutController
extends Node

signal weapon_style_changed(style_data: WeaponStyleData)

@export var combat_controller: CombatController
@export var available_styles: Array[WeaponStyleData] = []
@export var starting_style_index: int = 0

var current_style_index: int = -1
var current_style: WeaponStyleData

func _ready() -> void:
	if available_styles.is_empty():
		push_warning("WeaponLoadoutController has no available styles.")
		return

	equip_style_by_index(starting_style_index)

func equip_style_by_index(index: int) -> void:
	if available_styles.is_empty():
		return

	if combat_controller != null and combat_controller.is_attacking():
		print("Cannot switch weapon style while attacking.")
		return

	if index < 0 or index >= available_styles.size():
		push_warning("Weapon style index out of range: " + str(index))
		return

	var style_data := available_styles[index]

	if style_data == null:
		push_warning("Weapon style slot is empty: " + str(index))
		return

	current_style_index = index
	current_style = style_data

	if combat_controller != null:
		combat_controller.equip_weapon_style(style_data)

	print("Current weapon style: ", current_style.display_name)
	weapon_style_changed.emit(current_style)

func equip_next_style() -> void:
	if available_styles.is_empty():
		return

	var next_index := current_style_index + 1

	if next_index >= available_styles.size():
		next_index = 0

	equip_style_by_index(next_index)

func equip_previous_style() -> void:
	if available_styles.is_empty():
		return

	var previous_index := current_style_index - 1

	if previous_index < 0:
		previous_index = available_styles.size() - 1

	equip_style_by_index(previous_index)

func get_current_style() -> WeaponStyleData:
	return current_style
