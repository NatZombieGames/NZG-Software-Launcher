extends HBoxContainer

@export var colour : Color = Color.WHITE:
	set(value):
		colour = value
		$Button/Container/Preview.color = colour
		$Picker/MarginContainer/Container/Preview.color = colour
		$Picker/MarginContainer/Container/Row1/Slider.set_value_no_signal(colour.r)
		$Picker/MarginContainer/Container/Row1/Spinbox.value = colour.r
		$Picker/MarginContainer/Container/Row2/Slider.set_value_no_signal(colour.g)
		$Picker/MarginContainer/Container/Row2/Spinbox.value = colour.g
		$Picker/MarginContainer/Container/Row3/Slider.set_value_no_signal(colour.b)
		$Picker/MarginContainer/Container/Row3/Spinbox.value = colour.b
		self.emit_signal(&"colour_changed", colour)
@export var title : String = "Colour Picker":
	set(value):
		title = value
		$Button/Container/Title.text = " " + value + " "
@export var picker_open : bool = false:
	set(value):
		picker_open = value
		$Picker.visible = picker_open
		await get_tree().process_frame
		self.size = Vector2.ZERO
signal colour_changed(new_colour : Color)

func _ready() -> void:
	$Button/Button.toggled.connect(func(state : bool) -> void: picker_open = state; return)
	$Picker/MarginContainer/Container/Row1/Slider.value_changed.connect(func(val : float) -> void: colour.r = val; colour = colour; return)
	$Picker/MarginContainer/Container/Row2/Slider.value_changed.connect(func(val : float) -> void: colour.g = val; colour = colour; return)
	$Picker/MarginContainer/Container/Row3/Slider.value_changed.connect(func(val : float) -> void: colour.b = val; colour = colour; return)
	$Picker/MarginContainer/Container/Row1/Spinbox.value_changed.connect(func(val : float) -> void: colour.r = val; colour = colour; return)
	$Picker/MarginContainer/Container/Row2/Spinbox.value_changed.connect(func(val : float) -> void: colour.g = val; colour = colour; return)
	$Picker/MarginContainer/Container/Row3/Spinbox.value_changed.connect(func(val : float) -> void: colour.b = val; colour = colour; return)
	if not IconLoader.finished_loading_icons:
		await IconLoader.finished_loading_icons_signal
	for slider : HSlider in [$Picker/MarginContainer/Container/Row1/Slider, $Picker/MarginContainer/Container/Row2/Slider, $Picker/MarginContainer/Container/Row3/Slider]:
		slider.set(&"theme_override_icons/grabber", IconLoader.icons[&"Selection"])
		slider.set(&"theme_override_icons/grabber_highlight", IconLoader.icons[&"Selection"])
	return
