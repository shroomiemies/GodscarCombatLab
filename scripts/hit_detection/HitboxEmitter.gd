class_name HitboxEmitter
extends Node3D

signal hurtbox_hit(hit_result: HitResult)

@export var debug_material: Material
@export var linger_debug_material: Material
@export_flags_3d_physics var hurtbox_collision_mask: int = 1 << 3
@export var source_actor: Node3D

var active_debug_meshes: Array[Node3D] = []
var lingering_debug_meshes: Array[Node3D] = []
var previous_attack_time: float = 0.0
var previous_global_transform: Transform3D
var has_previous_trace_sample: bool = false
var hit_actors_this_attack: Dictionary = {}
var current_attack_data: AttackData

func _ready() -> void:
	previous_global_transform = global_transform

func begin_attack_trace() -> void:
	clear_debug_hitboxes()
	hit_actors_this_attack.clear()
	current_attack_data = null
	previous_attack_time = 0.0
	previous_global_transform = global_transform
	has_previous_trace_sample = false

func clear_debug_hitboxes() -> void:
	for mesh in active_debug_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()

	active_debug_meshes.clear()

func clear_all_debug_hitboxes() -> void:
	clear_debug_hitboxes()

	for mesh in lingering_debug_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()

	lingering_debug_meshes.clear()
	current_attack_data = null
	has_previous_trace_sample = false

func show_attack_debug(attack_data: AttackData, attack_time: float) -> void:
	clear_debug_hitboxes()

	current_attack_data = attack_data

	if attack_data == null:
		has_previous_trace_sample = false
		return

	_show_simple_hit_volumes(attack_data, attack_time)
	_show_weapon_traces(attack_data, attack_time)

	previous_attack_time = attack_time
	previous_global_transform = global_transform
	has_previous_trace_sample = true

func _show_simple_hit_volumes(attack_data: AttackData, attack_time: float) -> void:
	for hit_volume in attack_data.hit_volumes:
		if hit_volume == null:
			continue

		if attack_time < hit_volume.start_time:
			continue

		if attack_time > hit_volume.end_time:
			continue

		_spawn_simple_debug_mesh(hit_volume)

func _spawn_simple_debug_mesh(hit_volume: HitVolumeData) -> void:
	if not hit_volume.debug_visible:
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "DebugHitVolume"

	match hit_volume.shape_type:
		HitVolumeData.ShapeType.BOX:
			var box_mesh := BoxMesh.new()
			box_mesh.size = hit_volume.box_size
			mesh_instance.mesh = box_mesh

		HitVolumeData.ShapeType.SPHERE:
			var sphere_mesh := SphereMesh.new()
			sphere_mesh.radius = hit_volume.sphere_radius
			mesh_instance.mesh = sphere_mesh

		HitVolumeData.ShapeType.CAPSULE:
			var capsule_mesh := CapsuleMesh.new()
			capsule_mesh.radius = hit_volume.capsule_radius
			capsule_mesh.height = hit_volume.capsule_height
			mesh_instance.mesh = capsule_mesh

	if debug_material != null:
		mesh_instance.material_override = debug_material

	add_child(mesh_instance)

	mesh_instance.position = hit_volume.local_position
	mesh_instance.rotation_degrees = hit_volume.local_rotation_degrees

	active_debug_meshes.append(mesh_instance)

func _show_weapon_traces(attack_data: AttackData, attack_time: float) -> void:
	if not has_previous_trace_sample:
		return

	for trace in attack_data.weapon_traces:
		if trace == null:
			continue

		if not trace.debug_visible:
			continue

		_show_weapon_trace(trace, previous_attack_time, attack_time, previous_global_transform, global_transform)

func _show_weapon_trace(
	trace: WeaponTraceData,
	from_attack_time: float,
	to_attack_time: float,
	from_transform: Transform3D,
	to_transform: Transform3D
) -> void:
	if to_attack_time <= trace.start_time:
		return

	if from_attack_time >= trace.end_time:
		return

	var clamped_from_time :float = clamp(from_attack_time, trace.start_time, trace.end_time)
	var clamped_to_time :float = clamp(to_attack_time, trace.start_time, trace.end_time)

	if clamped_to_time <= clamped_from_time:
		return

	var trace_duration := trace.end_time - trace.start_time

	if trace_duration <= 0.0:
		return

	var from_t := (clamped_from_time - trace.start_time) / trace_duration
	var to_t := (clamped_to_time - trace.start_time) / trace_duration

	var subsegment_count := _get_subsegment_count(trace, from_t, to_t)

	for i in range(subsegment_count):
		var segment_from_t :float = lerp(from_t, to_t, float(i) / float(subsegment_count))
		var segment_to_t :float = lerp(from_t, to_t, float(i + 1) / float(subsegment_count))

		var segment_from_transform := _interpolate_transform(from_transform, to_transform, float(i) / float(subsegment_count))
		var segment_to_transform := _interpolate_transform(from_transform, to_transform, float(i + 1) / float(subsegment_count))

		var points := _build_swept_trace_points(
			trace,
			segment_from_t,
			segment_to_t,
			segment_from_transform,
			segment_to_transform
		)

		_spawn_swept_trace_debug_mesh(points, trace.debug_linger_time)
		_query_swept_trace_hits(points)

func _query_swept_trace_hits(points: PackedVector3Array) -> void:
	if points.size() != 8:
		return

	var shape := ConvexPolygonShape3D.new()
	shape.points = points

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D.IDENTITY
	query.collision_mask = hurtbox_collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var space_state := get_world_3d().direct_space_state
	var results := space_state.intersect_shape(query, 32)

	for result in results:
		var collider :Object = result.get("collider")

		if collider == null:
			continue

		if not collider is Hurtbox:
			continue

		var hurtbox := collider as Hurtbox
		_register_hurtbox_hit(hurtbox)

func _register_hurtbox_hit(hurtbox: Hurtbox) -> void:
	if hurtbox == null:
		return

	var hit_actor := hurtbox.get_owner_actor()

	if hit_actor == null:
		return

	if source_actor != null and hit_actor == source_actor:
		return

	if hit_actors_this_attack.has(hit_actor):
		return

	hit_actors_this_attack[hit_actor] = true

	var hit_result := HitResult.new()
	hit_result.hurtbox = hurtbox
	hit_result.actor = hit_actor
	hit_result.attack_data = current_attack_data
	hit_result.source = source_actor
	hit_result.hit_position = hurtbox.global_position

	var attack_id: StringName = &"unknown_attack"

	if current_attack_data != null:
		attack_id = current_attack_data.attack_id

	print("Hit: ", hit_actor.name, " with ", attack_id)

	hurtbox_hit.emit(hit_result)

func _get_subsegment_count(trace: WeaponTraceData, from_t: float, to_t: float) -> int:
	var crossed_fraction :float = abs(to_t - from_t)
	var count := ceili(float(trace.sample_count) * crossed_fraction)
	return maxi(count, 1)

func _interpolate_transform(from_transform: Transform3D, to_transform: Transform3D, weight: float) -> Transform3D:
	var from_quat := from_transform.basis.get_rotation_quaternion()
	var to_quat := to_transform.basis.get_rotation_quaternion()

	var blended_quat := from_quat.slerp(to_quat, weight)
	var blended_basis := Basis(blended_quat)

	var blended_origin := from_transform.origin.lerp(to_transform.origin, weight)

	return Transform3D(blended_basis, blended_origin)

func _build_swept_trace_points(
	trace: WeaponTraceData,
	from_t: float,
	to_t: float,
	from_transform: Transform3D,
	to_transform: Transform3D
) -> PackedVector3Array:
	var from_points := _get_trace_sample_points(trace, from_t, from_transform)
	var to_points := _get_trace_sample_points(trace, to_t, to_transform)

	var points := PackedVector3Array()

	for point in from_points:
		points.append(point)

	for point in to_points:
		points.append(point)

	return points

func _get_trace_sample_points(
	trace: WeaponTraceData,
	normalized_time: float,
	base_transform: Transform3D
) -> Array[Vector3]:
	var local_transform := Transform3D(
		Basis.from_euler(Vector3(
			deg_to_rad(trace.local_rotation_degrees.x),
			deg_to_rad(trace.local_rotation_degrees.y),
			deg_to_rad(trace.local_rotation_degrees.z)
		)),
		trace.local_position
	)

	var combined_transform := base_transform * local_transform

	var angle :float = lerp(deg_to_rad(trace.start_angle_degrees)
		,deg_to_rad(trace.end_angle_degrees),
		normalized_time
	)

	var direction := Vector3(sin(angle), 0.0, -cos(angle)).normalized()

	var inner_center := direction * trace.inner_radius
	var outer_center := direction * trace.outer_radius

	var lower_y := trace.height - trace.vertical_thickness * 0.5
	var upper_y := trace.height + trace.vertical_thickness * 0.5

	var inner_lower := inner_center + Vector3(0.0, lower_y, 0.0)
	var inner_upper := inner_center + Vector3(0.0, upper_y, 0.0)
	var outer_lower := outer_center + Vector3(0.0, lower_y, 0.0)
	var outer_upper := outer_center + Vector3(0.0, upper_y, 0.0)

	return [
		combined_transform * inner_lower,
		combined_transform * inner_upper,
		combined_transform * outer_lower,
		combined_transform * outer_upper,
	]

func _spawn_swept_trace_debug_mesh(points: PackedVector3Array, linger_time: float) -> void:
	if points.size() != 8:
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "DebugSweptTrace"

	var array_mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()

	for point in points:
		vertices.append(point)

	# Points:
	# 0 previous inner lower
	# 1 previous inner upper
	# 2 previous outer lower
	# 3 previous outer upper
	# 4 current inner lower
	# 5 current inner upper
	# 6 current outer lower
	# 7 current outer upper

	_add_quad_indices(indices, 0, 2, 3, 1) # previous sample face
	_add_quad_indices(indices, 4, 5, 7, 6) # current sample face
	_add_quad_indices(indices, 0, 1, 5, 4) # inner side
	_add_quad_indices(indices, 2, 6, 7, 3) # outer side
	_add_quad_indices(indices, 1, 3, 7, 5) # top
	_add_quad_indices(indices, 0, 4, 6, 2) # bottom

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh

	if debug_material != null:
		mesh_instance.material_override = debug_material

	# Points are already world-space.
	get_tree().current_scene.add_child(mesh_instance)

	# Swept traces should linger instead of being cleared every frame.
	lingering_debug_meshes.append(mesh_instance)

	if linger_time <= 0.0:
		return

	var mesh_ref :Object = weakref(mesh_instance)
	var timer := get_tree().create_timer(linger_time)

	timer.timeout.connect(func() -> void:
		var mesh := mesh_ref.get_ref() as Node3D

		if mesh == null:
			return

		lingering_debug_meshes.erase(mesh)

		if is_instance_valid(mesh):
			mesh.queue_free()
	)

func _add_quad_indices(indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)

	indices.append(a)
	indices.append(c)
	indices.append(d)
