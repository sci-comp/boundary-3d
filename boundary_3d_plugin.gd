@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"Boundary3D",
		"Node3D", 
		preload("res://addons/boundary_3d/boundary_3d.gd"),
		preload("res://addons/boundary_3d/boundary_3d.svg")
	)

func _exit_tree():
	remove_custom_type("Boundary3D")

func _handles(object):
	return has_active_boundary_tool()

func has_active_boundary_tool() -> bool:
	var edited_scene = EditorInterface.get_edited_scene_root()
	if not edited_scene:
		return false
	return find_active_boundary_recursive(edited_scene) != null

func find_active_boundary_recursive(node: Node) -> Boundary3D:
	if node is Boundary3D and node.tool_active:
		return node
	for child in node.get_children():
		var result = find_active_boundary_recursive(child)
		if result:
			return result
	return null

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	var active_boundary = find_active_boundary_recursive(EditorInterface.get_edited_scene_root())
	if active_boundary and active_boundary.handle_click(viewport_camera, event):
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	if active_boundary:
		# Force selection back to boundary node, if active
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(active_boundary)
	return EditorPlugin.AFTER_GUI_INPUT_PASS
