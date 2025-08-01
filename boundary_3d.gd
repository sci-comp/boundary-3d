@tool
extends Node3D
class_name Boundary3D

@export var tool_active: bool = false : set = set_tool_active
@export var cleanup: bool = false : set = set_cleanup

@export_group("Boundary Settings")
@export var height: float = 20.0
@export var width: float = 1.0
@export var collision_layer: int = 1
@export var collision_mask: int = 1

@export_group("Visual Settings")
@export var preview_color: Color = Color(0.0, 0.5, 1.0, 0.3)
@export var point_marker_color: Color = Color(1.0, 0.5, 0.0, 0.8)

var click_points: Array[Vector3]
var preview_meshes: Array[MeshInstance3D]
var point_markers: Array[MeshInstance3D]
var preview_material: StandardMaterial3D
var point_marker_material: StandardMaterial3D

func _ready():
	if Engine.is_editor_hint():
		add_to_group("boundary_3d_tools")
		create_materials()

func _exit_tree():
	if Engine.is_editor_hint():
		remove_from_group("boundary_3d_tools")

func set_tool_active(active: bool):
	tool_active = active
	if Engine.is_editor_hint():
		if active:
			clear_all()
			print("[Boundary3D] Activated, click collision shapes to place points")
		else:
			if click_points.size() >= 2:
				finish_boundaries()
			else:
				clear_all()
			print("[Boundary3D] Deactivated")

func set_cleanup(value: bool):
	if value and Engine.is_editor_hint():
		clear_all()
		set_tool_active(false)
		set_script(null)
		print("[Boundary3D] Script removed")

func handle_click(camera: Camera3D, event: InputEvent) -> bool:
	if not tool_active:
		return false
	
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var hit_result = raycast_from_camera(camera, mouse_event.position)
			if hit_result.has("position"):
				add_click_point(hit_result.position)
			return true
	
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed:
			if key_event.keycode == KEY_ESCAPE:
				remove_last_point()
				return true
			elif key_event.keycode == KEY_ENTER:
				finish_boundaries()
				return true
			elif key_event.keycode == KEY_C and key_event.ctrl_pressed:
				clear_all()
				return true
	
	return false

func raycast_from_camera(camera: Camera3D, mouse_pos: Vector2) -> Dictionary:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 5000.0
	
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0xFFFFFFFF
	
	return space_state.intersect_ray(query)

func add_click_point(point: Vector3):
	click_points.append(point)
	create_point_marker(point)
	
	if click_points.size() >= 2:
		var start = click_points[click_points.size() - 2]
		var end = click_points[click_points.size() - 1]
		create_preview_segment(start, end)
	
	print("[Boundary3D] Points: %d" % click_points.size())

func remove_last_point():
	if click_points.size() == 0:
		return
	
	click_points.pop_back()
	
	if point_markers.size() > 0:
		point_markers.pop_back().queue_free()
	
	if preview_meshes.size() > 0:
		preview_meshes.pop_back().queue_free()
	
	print("[Boundary3D] Points: %d (removed last)" % click_points.size())

func clear_all():
	click_points.clear()
	clear_point_markers()
	clear_previews_only()

func clear_point_markers():
	for marker in point_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	point_markers.clear()

func finish_boundaries():
	if click_points.size() < 2:
		print("[Boundary3D] Need at least 2 points")
		return
	
	clear_previews_only()
	
	for i in range(click_points.size() - 1):
		var start = click_points[i]
		var end = click_points[i + 1]
		var boundary = create_boundary_node(start, end, i + 1)
		add_child(boundary)
		boundary.owner = get_tree().edited_scene_root
		
		for child in boundary.get_children():
			child.owner = get_tree().edited_scene_root
	
	var count = click_points.size() - 1
	click_points.clear()
	clear_point_markers()
	print("[Boundary3D] Created %d boundaries" % count)

func clear_previews_only():
	for preview in preview_meshes:
		if is_instance_valid(preview):
			preview.queue_free()
	preview_meshes.clear()

func create_point_marker(point: Vector3):
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	marker.mesh = sphere
	marker.material_override = point_marker_material
	marker.position = point
	add_child(marker)
	point_markers.append(marker)

func create_preview_segment(start: Vector3, end: Vector3):
	var preview = MeshInstance3D.new()
	var box = BoxMesh.new()
	var length = start.distance_to(end)
	box.size = Vector3(width, height, length)
	preview.mesh = box
	preview.material_override = preview_material
	preview.transform = calculate_transform(start, end)
	add_child(preview)
	preview_meshes.append(preview)

func create_boundary_node(start: Vector3, end: Vector3, index: int) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = "StaticBody3D_%03d" % index
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	
	var shape = CollisionShape3D.new()
	shape.name = "CollisionShape3D_%03d" % index
	var box = BoxShape3D.new()
	var length = start.distance_to(end)
	box.size = Vector3(width, height, length)
	shape.shape = box
	
	body.add_child(shape)
	body.transform = calculate_transform(start, end)
	return body

func calculate_transform(start: Vector3, end: Vector3) -> Transform3D:
	var center = (start + end) * 0.5
	var direction = (end - start).normalized()
	var transform = Transform3D()
	transform.origin = center
	
	if direction.length() > 0.001:
		var angle = atan2(direction.x, direction.z)
		transform.basis = Basis(Vector3.UP, angle)  # Boundaries are vertically aligned 
	
	return transform

func create_materials():
	preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = preview_color
	preview_material.flags_transparent = true
	preview_material.flags_unshaded = true
	preview_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	point_marker_material = StandardMaterial3D.new()
	point_marker_material.albedo_color = point_marker_color
	point_marker_material.flags_transparent = true
	point_marker_material.flags_unshaded = true
