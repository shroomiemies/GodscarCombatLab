class_name MovementFrame
extends RefCounted

var origin: Vector3 = Vector3.ZERO
var basis: Basis = Basis.IDENTITY
var up: Vector3 = Vector3.UP
var linear_velocity: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

	
static func world() -> MovementFrame:
	var frame := MovementFrame.new()
	frame.origin = Vector3.ZERO
	frame.basis = Basis.IDENTITY
	frame.up = Vector3.UP
	frame.linear_velocity = Vector3.ZERO
	frame.angular_velocity = Vector3.ZERO
	return frame
	
func local_direction_to_world(local_direction: Vector3) -> Vector3:
	return basis * local_direction
	
func world_direction_to_local(world_direction: Vector3) -> Vector3:
	return basis.inverse() * world_direction
