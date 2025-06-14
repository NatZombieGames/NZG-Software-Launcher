extends Node
##The manager of everything colour and theme related

##The colour for all backgrounds and parts of panels that are classified as 'Background 1'
@export var background_1_colour : Color = default_colours[&"Background 1"]:
	set(value):
		background_1_colour = value
		apply_colours()
##The colour for all backgrounds and parts of panels that are classified as 'Background 2'
@export var background_2_colour : Color = default_colours[&"Background 2"]:
	set(value):
		background_2_colour = value
		apply_colours()
##The colour for all backgrounds and parts of panels that are classified as 'Separator'
@export var separator_colour : Color = default_colours[&"Separator"]:
	set(value):
		separator_colour = value
		apply_colours()
##The colour for all backgrounds and parts of panels that are classified as 'Highlight 1'
@export var highlight_1_colour : Color = default_colours[&"Highlight 1"]:
	set(value):
		highlight_1_colour = value
		apply_colours()
##The colour for all backgrounds and parts of panels that are classified as 'Highlight 2'
@export var highlight_2_colour : Color = default_colours[&"Highlight 2"]:
	set(value):
		highlight_2_colour = value
		apply_colours()
@export var shaded_colour : Color = default_colours[&"Shaded"]:
	set(value):
		shaded_colour = value
		apply_colours()
##All the styleboxes used which the ColourManager can alter
var styleboxes : Dictionary[StringName, StyleBoxFlat] = {
	&"PopupPageStylebox": preload("res://Assets/Styleboxes/PopupPageStylebox.tres"), 
	&"WindowButtonsBackgroundStylebox": preload("res://Assets/Styleboxes/WindowButtonsBackgroundStylebox.tres"), 
	&"CustomButtonNormalStylebox": preload("res://Assets/Styleboxes/CustomButtonNormalStylebox.tres"), 
	&"CustomButtonHoverStylebox": preload("res://Assets/Styleboxes/CustomButtonHoverStylebox.tres"), 
	&"CustomButtonPressedStylebox": preload("res://Assets/Styleboxes/CustomButtonPressedStylebox.tres"), 
	&"CustomButtonDisabledStylebox": preload("res://Assets/Styleboxes/CustomButtonDisabledStylebox.tres"), 
	&"ContainerStylebox": preload("res://Assets/Styleboxes/ContainerStylebox.tres"), 
	&"ProductListItemStylebox": preload("res://Assets/Styleboxes/ProductListItemStylebox.tres"), 
	&"ProductListItemHoveredStylebox": preload("res://Assets/Styleboxes/ProductListItemHoveredStylebox.tres"), 
}
##The names of the colour
const colours : PackedStringArray = [&"Background 1", &"Background 2", &"Separator", &"Highlight 1", &"Highlight 2", &"Shaded"]
##The default colour scheme
const default_colours : Dictionary[StringName, Color] = {
	&"Background 1": Color(0.047, 0.047, 0.055), 
	&"Background 2": Color(0.067, 0.067, 0.075), 
	&"Separator": Color(0.078, 0.078, 0.086), 
	&"Highlight 1": Color(0.098, 0.098, 0.106), 
	&"Highlight 2": Color(0.118, 0.118, 0.125), 
	&"Shaded": Color(0.039, 0.039, 0.043), 
	}

func _ready() -> void:
	apply_colours()
	return

##Applies all the colours to the panels and nodes in the appropriate groups
func apply_colours() -> void:
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_BUSY)
	await get_tree().process_frame
	#
	get_tree().set_group(&"Background 1", &"color", background_1_colour)
	get_tree().set_group(&"Background 2", &"color", background_2_colour)
	get_tree().set_group(&"Separator", &"color", separator_colour)
	get_tree().set_group(&"Shaded", &"color", shaded_colour)
	styleboxes[&"PopupPageStylebox"].bg_color = background_1_colour
	styleboxes[&"PopupPageStylebox"].border_color = separator_colour
	styleboxes[&"WindowButtonsBackgroundStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonNormalStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonNormalStylebox"].border_color = separator_colour
	styleboxes[&"CustomButtonHoverStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonHoverStylebox"].border_color = highlight_1_colour
	styleboxes[&"CustomButtonPressedStylebox"].bg_color = background_2_colour
	styleboxes[&"CustomButtonPressedStylebox"].border_color = highlight_2_colour
	styleboxes[&"CustomButtonDisabledStylebox"].bg_color = shaded_colour
	styleboxes[&"CustomButtonDisabledStylebox"].border_color = shaded_colour
	styleboxes[&"ContainerStylebox"].border_color = highlight_1_colour
	styleboxes[&"ProductListItemStylebox"].bg_color = background_2_colour
	styleboxes[&"ProductListItemStylebox"].border_color = separator_colour
	styleboxes[&"ProductListItemHoveredStylebox"].bg_color = background_2_colour
	styleboxes[&"ProductListItemHoveredStylebox"].border_color = highlight_2_colour
	for node : Control in get_tree().get_nodes_in_group(&"Stylebox Haver"):
		match node.get_class():
			"PanelContainer":
				if not node.get_meta(&"DontSetPanel", false):
					node.set(&"theme_override_styles/panel", styleboxes[node.get_meta(&"StyleboxName", &"")])
			"Button":
				for box : String in ["normal", "pressed", "hover", "disabled"]:
					node.set(StringName("theme_override_styles/" + box), styleboxes[StringName(String(node.get_meta(&"StyleboxName", &"")) + box.capitalize() + "Stylebox")])
	#
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_ARROW)
	return

##Applies the settings from [b]UserManager[/b].settings[lb]&"ColourSettings"[rb]
func apply_colour_settings(settings : Dictionary[StringName, Color]) -> void:
	for group : StringName in settings.keys():
		self.set(String(group).to_snake_case() + "_colour", settings[group])
	return

##Compiles a [Dictionary] of [lb][StringName], [Color][rb] containing the current colour settings to be saved to [b]UserManager[/b].settings[lb]&"ColourSettings"[rb]
func get_colour_settings() -> Dictionary[StringName, Color]:
	var to_return : Dictionary[StringName, Color] = {}
	for colour_name : StringName in colours:
		to_return[colour_name] = self.get(String(colour_name).to_snake_case() + "_colour")
	return to_return
