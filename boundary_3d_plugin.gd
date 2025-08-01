@tool
extends EditorPlugin

var active_boundary : Boundary3D

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
	var boundaries = get_tree().get_nodes_in_group("boundary_3d_tools")
	for boundary in boundaries:
		if boundary.tool_active:
			return true
	return false

func find_active_boundary() -> Boundary3D:
	var boundaries = get_tree().get_nodes_in_group("boundary_3d_tools")
	for boundary in boundaries:
		if boundary.tool_active:
			return boundary
	return null

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	var active_boundary = find_active_boundary()
	if active_boundary and active_boundary.handle_click(viewport_camera, event):
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	if active_boundary:
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(active_boundary)
	return EditorPlugin.AFTER_GUI_INPUT_PASS
	
