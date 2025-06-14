extends Control

const custom_colour_picker_button : PackedScene = preload("res://Scenes/CustomColourPickerButton.tscn")

func _ready() -> void:
	%List.visible = false
	$ScrollContainer/List/ResetButton.pressed.connect(func() -> void: ColourManager.apply_colour_settings(ColourManager.default_colours); update_colours(); return)
	for colour : StringName in ColourManager.colours:
		%List/ColourStuff.add_child(custom_colour_picker_button.instantiate())
		%List/ColourStuff.get_child(-1).colour = ColourManager.get(colour.to_snake_case() + "_colour")
		%List/ColourStuff.get_child(-1).title = colour
		%List/ColourStuff.get_child(-1).colour_changed.connect(Callable(self, &"set_colour").bind(colour))
	%List.visible = true
	return

func update_colours() -> void:
	for colour : StringName in ColourManager.colours:
		%List/ColourStuff.get_child(ColourManager.colours.find(colour)).colour = ColourManager.get(colour.to_snake_case() + "_colour")
	return

func set_colour(colour : Color, colour_name : StringName) -> void:
	ColourManager.set(colour_name.to_snake_case() + "_colour", colour)
	ColourManager.apply_colours()
	return
