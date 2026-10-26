@tool
extends EditorPlugin

## Editor entry point for dot-flashlight. No autoloads: a flashlight belongs to a player, and a process that runs a server and a client needs two of everything.


func _enter_tree() -> void:
	add_custom_type("DotFlashlight", "Node", load("res://addons/dot_flashlight/runtime/dot_flashlight.gd"), null)


func _exit_tree() -> void:
	remove_custom_type("DotFlashlight")
