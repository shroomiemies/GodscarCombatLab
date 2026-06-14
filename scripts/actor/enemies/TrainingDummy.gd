class_name TrainingDummy
extends CharacterBody3D

@export var target_display_name: String = "Training Dummy"

@onready var target_point: Marker3D = $TargetPoint

func get_target_point() -> Vector3:
	if target_point == null:
		return global_position + Vector3.UP * 1.2

	return target_point.global_position
