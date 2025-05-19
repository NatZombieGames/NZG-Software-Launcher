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
@export var highlight_1_colour : Color = Color(0.098, 0.098, 0.106):
	set(value):
		highlight_1_colour = value
		apply_colours()
@export var highlight_2_colour : Color = Color(0.118, 0.118, 0.125):
	set(value):
		highlight_2_colour = value
		apply_colours()
var styleboxes : Dictionary[StringName, StyleBoxFlat] = {
	&"PopupPageStylebox": preload("res://Assets/Styleboxes/PopupPageStylebox.tres"), 
	&"WindowButtonsBackgroundStylebox": preload("res://Assets/Styleboxes/WindowButtonsBackgroundStylebox.tres"), 
	&"CustomButtonNormalStylebox": preload("res://Assets/Styleboxes/CustomButtonNormalStylebox.tres"), 
	&"CustomButtonHoverStylebox": preload("res://Assets/Styleboxes/CustomButtonHoverStylebox.tres"), 
	&"CustomButtonPressedStylebox": preload("res://Assets/Styleboxes/CustomButtonPressedStylebox.tres"), 
	&"ContainerStylebox": preload("res://Assets/Styleboxes/ContainerStylebox.tres"), 
	&"ProductListItemStylebox": preload("res://Assets/Styleboxes/ProductListItemStylebox.tres"), 
	&"ProductListItemHoveredStylebox": preload("res://Assets/Styleboxes/ProductListItemHoveredStylebox.tres"), 
}
const colours : PackedStringArray = [&"Background 1", &"Background 2", &"Separator", &"Highlight 1", &"Highlight 2"]

func _ready() -> void:
	apply_colours()
	return

func apply_colours() -> void:
	get_tree().set_group(&"Background 1", &"color", background_1_colour)
	get_tree().set_group(&"Background 2", &"color", background_2_colour)
	get_tree().set_group(&"Separator", &"color", separator_colour)
	styleboxes[&"PopupPageStylebox"].bg_color = background_1_colour
	styleboxes[&"PopupPageStylebox"].border_color = separator_colour
	styleboxes[&"WindowButtonsBackgroundStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonNormalStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonNormalStylebox"].border_color = separator_colour
	styleboxes[&"CustomButtonHoverStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonHoverStylebox"].border_color = highlight_1_colour
	styleboxes[&"CustomButtonPressedStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonPressedStylebox"].border_color = highlight_2_colour
	styleboxes[&"ContainerStylebox"].border_color = highlight_1_colour
	styleboxes[&"ProductListItemStylebox"].bg_color = background_2_colour
	styleboxes[&"ProductListItemStylebox"].border_color = separator_colour
	styleboxes[&"ProductListItemHoveredStylebox"].bg_color = background_2_colour
	styleboxes[&"ProductListItemHoveredStylebox"].border_color = highlight_2_colour
	for node : Control in get_tree().get_nodes_in_group(&"Stylebox Haver"):
		#print(node.name)
		#print(node.get_path())
		#print(node.get_meta_list())
		#print("'", node.get_meta(&"StyleboxName", &""), "'")
		#print(styleboxes.keys())
		match node.get_class():
			"PanelContainer":
				if not node.get_meta(&"CustomTextureButton", false):
					node.set(&"theme_override_styles/panel", styleboxes[node.get_meta(&"StyleboxName", &"")])
			"Button":
				for box : String in ["normal", "pressed", "hover"]:
					node.set(StringName("theme_override_styles/" + box), styleboxes[StringName(String(node.get_meta(&"StyleboxName", &"")) + box.capitalize() + "Stylebox")])
	return

func apply_colour_settings(settings : Dictionary[StringName, Color]) -> void:
	for group : StringName in settings.keys():
		self.set(String(group).to_snake_case() + "_colour", settings[group])
	return

func get_colour_settings() -> Dictionary[StringName, Color]:
	var to_return : Dictionary[StringName, Color] = {}
	for colour_name : StringName in colours:
		to_return[colour_name] = self.get(String(colour_name).to_snake_case() + "_colour")
	return to_return
