extends Node

@export var background_1_colour : Color = Color(0.047, 0.047, 0.055):
	set(value):
		background_1_colour = value
		apply_colours()
@export var background_2_colour : Color = Color(0.067, 0.067, 0.075):
	set(value):
		background_2_colour = value
		apply_colours()
@export var separator_colour : Color = Color(0.078, 0.078, 0.086):
	set(value):
		separator_colour = value
		apply_colours()
var styleboxes : Dictionary[StringName, StyleBoxFlat] = {
	&"PopupPageStylebox": preload("res://Assets/Styleboxes/PopupPageStylebox.tres"), 
	&"WindowButtonsBackgroundStylebox": preload("res://Assets/Styleboxes/WindowButtonsBackgroundStylebox.tres"), 
}

func _ready() -> void:
	apply_colours()
	return

func apply_colours() -> void:
	get_tree().set_group(&"Background 1", &"color", background_1_colour)
	get_tree().set_group(&"Background 2", &"color", background_2_colour)
	get_tree().set_group(&"Separator", &"color", separator_colour)
	styleboxes[&"PopupPageStylebox"].bg_color = background_1_colour
	styleboxes[&"PopupPageStylebox"].border_color = separator_colour
	for node : Control in get_tree().get_nodes_in_group(&"Stylebox Haver"):
		print(node.name)
		print(node.get_path())
		print(node.get_meta_list())
		print("'", node.get_meta(&"StyleboxName", &""), "'")
		print(styleboxes.keys())
		node.set(&"theme_override_styles/panel", styleboxes[node.get_meta(&"StyleboxName", &"")])
	return
