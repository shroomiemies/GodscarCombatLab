class_name Hurtbox
extends Area3D

@export var owner_actor: Node3D
@export var hurtbox_name: StringName = &"body"

func get_owner_actor() -> Node3D:
	if owner_actor != null:
		return owner_actor

	return owner as Node3D
