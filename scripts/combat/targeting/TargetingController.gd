class_name TargetingController
extends Node3D

@export var search_radius: float = 12.0
@export var max_lock_angle_degrees: float = 70.0
@export var current_target_marker_scene: PackedScene

var current_target: Node3D
var current_marker: Node3D

func has_target() -> bool:
	return current_target != null and is_instance_valid(current_target)

func clear_target() -> void:
	current_target = null

	if current_marker != null:
		current_marker.queue_free()
		current_marker = null

func toggle_lock_on(from_position: Vector3, look_forward: Vector3) -> void:
	if has_target():
		clear_target()
		return

	current_target = find_best_target(from_position, look_forward)
	_spawn_marker_if_needed()

func get_target_point() -> Vector3:
	if not has_target():
		return global_position

	if current_target.has_method("get_target_point"):
		return current_target.get_target_point()

	return current_target.global_position + Vector3.UP * 1.2

func find_best_target(from_position: Vector3, look_forward: Vector3) -> Node3D:
	var candidates := get_tree().get_nodes_in_group("targetable")

	var best_target: Node3D = null
	var best_score := INF

	var flat_forward := look_forward
	flat_forward.y = 0.0

	if flat_forward.length_squared() < 0.0001:
		return null

	flat_forward = flat_forward.normalized()

	var max_lock_angle := deg_to_rad(max_lock_angle_degrees)

	for candidate in candidates:
		if not candidate is Node3D:
			continue

		var candidate_node := candidate as Node3D
		var target_point := candidate_node.global_position

		if candidate_node.has_method("get_target_point"):
			target_point = candidate_node.get_target_point()

		var to_target := target_point - from_position
		to_target.y = 0.0

		var distance := to_target.length()

		if distance > search_radius:
			continue

		if distance <= 0.001:
			continue

		var direction := to_target.normalized()
		var angle := flat_forward.angle_to(direction)

		if angle > max_lock_angle:
			continue

		# Lower score is better.
		# Angle matters more than distance, but distance breaks ties.
		var score := angle * 10.0 + distance * 0.1

		if score < best_score:
			best_score = score
			best_target = candidate_node

	return best_target
	
func _process(_delta: float) -> void:
	if not has_target():
		if current_marker != null:
			current_marker.queue_free()
			current_marker = null
		return

	if current_marker != null:
		current_marker.global_position = get_target_point()


func _spawn_marker_if_needed() -> void:
	if not has_target():
		return

	if current_target_marker_scene == null:
		return

	if current_marker != null:
		current_marker.queue_free()

	current_marker = current_target_marker_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(current_marker)
	current_marker.global_position = get_target_point()
