class_name HitboxEmitter
extends Node3D

signal hurtbox_hit(hit_result: HitResult)

@export var debug_material: Material
@export var linger_debug_material: Material
@export_flags_3d_physics var hurtbox_collision_mask: int = 1 << 3
@export var source_actor: Node3D
@export var trace_origin_offset: Vector3 = Vector3.ZERO

var active_debug_meshes: Array[Node3D] = []
var lingering_debug_meshes: Array[Node3D] = []
var previous_attack_time: float = 0.0
var previous_global_transform: Transform3D
var has_previous_trace_sample: bool = false
var hit_actors_this_attack: Dictionary = {}
var current_attack_data: AttackData
var current_attack_charge_fraction: float = 0.0

func _ready() -> void:
	previous_global_transform = global_transform

func begin_attack_trace() -> void:
	clear_debug_hitboxes()
	hit_actors_this_attack.clear()
	current_attack_data = null
	current_attack_charge_fraction = 0.0
	previous_attack_time = 0.0
	previous_global_transform = global_transform
	has_previous_trace_sample = false
	
func get_hit_count_this_attack() -> int:
	return hit_actors_this_attack.size()

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

func show_attack_debug(
	attack_data: AttackData,
	attack_time: float,
	attack_charge_fraction: float = 0.0
) -> void:
	clear_debug_hitboxes()

	current_attack_data = attack_data
	current_attack_charge_fraction = attack_charge_fraction

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
	hit_result.charge_fraction = current_attack_charge_fraction
	hit_result.hit_position = hurtbox.global_position

	var attack_id: StringName = &"unknown_attack"

	if current_attack_data != null:
		attack_id = current_attack_data.attack_id

	print("Hit: ",hit_actor.name," with ",attack_id," charge ",
		str(roundi(current_attack_charge_fraction * 100.0)),"%")

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
	trace: WeaponTraceData,normalized_time: float,base_transform: Transform3D) -> Array[Vector3]:
	var origin_transform := Transform3D(Basis.IDENTITY, trace_origin_offset)
	var local_transform := _get_trace_local_transform(trace)
	var combined_transform := base_transform * origin_transform * local_transform
 
	match trace.trace_mode:
		WeaponTraceData.TraceMode.HORIZONTAL_ARC:
			return _get_horizontal_arc_sample_points(trace, normalized_time, combined_transform)

		WeaponTraceData.TraceMode.VERTICAL_ARC:
			return _get_vertical_arc_sample_points(trace, normalized_time, combined_transform)

		WeaponTraceData.TraceMode.THRUST:
			return _get_thrust_sample_points(trace, normalized_time, combined_transform)

		WeaponTraceData.TraceMode.LINEAR:
			return _get_linear_sample_points(trace, normalized_time, combined_transform)

		_:
			return _get_horizontal_arc_sample_points(trace, normalized_time, combined_transform)

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

func _get_trace_local_transform(trace: WeaponTraceData) -> Transform3D:
	var local_basis := Basis()
	local_basis = local_basis.rotated(Vector3.RIGHT, deg_to_rad(trace.local_rotation_degrees.x))
	local_basis = local_basis.rotated(Vector3.UP, deg_to_rad(trace.local_rotation_degrees.y))
	local_basis = local_basis.rotated(Vector3.FORWARD, deg_to_rad(trace.local_rotation_degrees.z))

	return Transform3D(local_basis, trace.local_position)
	
func _get_horizontal_arc_sample_points(
	trace: WeaponTraceData, normalized_time: float,
	combined_transform: Transform3D) -> Array[Vector3]:
	var angle :float = lerp(deg_to_rad(trace.start_angle_degrees), deg_to_rad(trace.end_angle_degrees), normalized_time)

	var radial_direction := Vector3(sin(angle), 0.0, -cos(angle)).normalized()
	var tangent_direction := Vector3(cos(angle), 0.0, sin(angle)).normalized()
	var up_direction := Vector3.UP

	var center_radius := (trace.inner_radius + trace.outer_radius) * 0.5
	var width := trace.outer_radius - trace.inner_radius
	var height_size := trace.vertical_thickness

	var center := radial_direction * center_radius + Vector3(0.0, trace.height, 0.0)

	return _build_oriented_sample_rectangle(
		center,
		radial_direction,
		up_direction,
		width,
		height_size,
		combined_transform
	)
	
func _get_vertical_arc_sample_points(
	trace: WeaponTraceData,
	normalized_time: float,
	combined_transform: Transform3D) -> Array[Vector3]:
	var x :float = lerp(
		trace.vertical_arc_start_x,
		trace.vertical_arc_end_x,
		normalized_time
	)

	var y :float = lerp(
		trace.vertical_arc_start_height,
		trace.vertical_arc_end_height,
		normalized_time
	)

	var arc_curve := sin(normalized_time * PI)
	var z := trace.vertical_arc_forward_offset \
		- arc_curve * trace.vertical_arc_depth_radius

	# Direction the blade is traveling through space.
	var path_direction := Vector3(
		trace.vertical_arc_end_x - trace.vertical_arc_start_x,
		trace.vertical_arc_end_height - trace.vertical_arc_start_height,
		0.0
	)

	if path_direction.length_squared() < 0.0001:
		path_direction = Vector3.DOWN

	path_direction = path_direction.normalized()

	var center_radius := (trace.inner_radius + trace.outer_radius) * 0.5
	var blade_length := trace.outer_radius - trace.inner_radius

	var center := Vector3(x,y,
		trace.vertical_arc_forward_offset - center_radius - arc_curve * trace.vertical_arc_depth_radius
	)

	var blade_length_axis := Vector3.FORWARD
	var blade_thickness_axis := Vector3.RIGHT

	return _build_oriented_sample_rectangle(
		center,
		blade_length_axis,
		blade_thickness_axis,
		blade_length,
		trace.blade_thickness,
		combined_transform
	)
	
func _get_thrust_sample_points(
	trace: WeaponTraceData,
	normalized_time: float,
	combined_transform: Transform3D
) -> Array[Vector3]:
	var center := trace.start_position.lerp(trace.end_position, normalized_time)

	var thrust_direction := (trace.end_position - trace.start_position)

	if thrust_direction.length_squared() < 0.0001:
		thrust_direction = Vector3.FORWARD * -1.0

	thrust_direction = thrust_direction.normalized()

	var width_axis := Vector3.RIGHT
	var height_axis := Vector3.UP

	return _build_oriented_sample_rectangle(
		center,
		width_axis,
		height_axis,
		trace.trace_width,
		trace.trace_height,
		combined_transform
	)
	
func _get_linear_sample_points(
	trace: WeaponTraceData,
	normalized_time: float,
	combined_transform: Transform3D
) -> Array[Vector3]:
	var center := trace.start_position.lerp(trace.end_position, normalized_time)

	var movement_direction := trace.end_position - trace.start_position

	if movement_direction.length_squared() < 0.0001:
		movement_direction = Vector3(0.0, 0.0, -1.0)

	movement_direction = movement_direction.normalized()

	var width_axis := Vector3.RIGHT
	var height_axis := Vector3.UP

	return _build_oriented_sample_rectangle(
		center,
		width_axis,
		height_axis,
		trace.trace_width,
		trace.trace_height,
		combined_transform
	)
	
func _build_oriented_sample_rectangle(
	center: Vector3,
	width_axis: Vector3,
	height_axis: Vector3,
	width: float,
	height_size: float,
	transform: Transform3D
) -> Array[Vector3]:
	if width_axis.length_squared() < 0.0001:
		width_axis = Vector3.RIGHT

	if height_axis.length_squared() < 0.0001:
		height_axis = Vector3.UP

	width_axis = width_axis.normalized()
	height_axis = height_axis.normalized()

	# Make axes orthogonal enough for a stable rectangle.
	height_axis = (height_axis - width_axis * height_axis.dot(width_axis))

	if height_axis.length_squared() < 0.0001:
		height_axis = Vector3.UP

	height_axis = height_axis.normalized()

	var half_width := width * 0.5
	var half_height := height_size * 0.5

	var left := center - width_axis * half_width
	var right := center + width_axis * half_width
	var lower_left := left - height_axis * half_height
	var upper_left := left + height_axis * half_height
	var lower_right := right - height_axis * half_height
	var upper_right := right + height_axis * half_height

	return [
		transform * lower_left,
		transform * upper_left,
		transform * lower_right,
		transform * upper_right,
	]
