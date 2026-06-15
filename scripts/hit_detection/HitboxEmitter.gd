class_name HitboxEmitter
extends Node3D

@export var debug_material: Material

var active_debug_meshes: Array[Node3D] = []

func clear_debug_hitboxes() -> void:
	for mesh in active_debug_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()

	active_debug_meshes.clear()

func show_hit_volumes(attack_data: AttackData, attack_time: float) -> void:
	clear_debug_hitboxes()

	if attack_data == null:
		return

	for hit_volume in attack_data.hit_volumes:
		if hit_volume == null:
			continue

		if attack_time < hit_volume.start_time:
			continue

		if attack_time > hit_volume.end_time:
			continue

		_spawn_debug_mesh(hit_volume)

func _spawn_debug_mesh(hit_volume: HitVolumeData) -> void:
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
