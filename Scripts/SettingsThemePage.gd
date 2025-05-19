extends Control

const custom_colour_picker_button : PackedScene = preload("res://Scenes/CustomColourPickerButton.tscn")

func _ready() -> void:
	%List.visible = false
	await get_tree().process_frame
	#
	for colour : StringName in ColourManager.colours:
		%List/ColourStuff.add_child(HBoxContainer.new())
		%List/ColourStuff.get_child(-1).alignment = BoxContainer.ALIGNMENT_CENTER
		%List/ColourStuff.get_child(-1).add_child(Label.new())
		%List/ColourStuff.get_child(-1).get_child(-1).text = colour
		%List/ColourStuff.get_child(-1).add_child(custom_colour_picker_button.instantiate())
		%List/ColourStuff.get_child(-1).get_child(-1).color = ColourManager.get(colour.to_snake_case() + "_colour")
		%List/ColourStuff.get_child(-1).get_child(-1).color_changed.connect(Callable(self, "set_colour").bind(colour))
	#
	await get_tree().process_frame
	%List.visible = true
	return

func set_colour(colour : Color, colour_name : StringName) -> void:
	ColourManager.set(colour_name.to_snake_case() + "_colour", colour)
	ColourManager.apply_colours()
	return
