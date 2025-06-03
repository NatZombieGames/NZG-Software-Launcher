extends ColorRect

const custom_button : PackedScene = preload("res://Scenes/CustomButton.tscn")

@export var open : bool = false:
	set(value):
		open = value
		GeneralManager.open_background_and_panel(open, self, $Panel)
@export var text : String = "":
	set(value):
		text = value
		%Text.text = text
@export var buttons_text : PackedStringArray = ["No", "Yes"]:
	set(value):
		buttons_text = value
		for btn : Button in %Buttons.get_children(): btn.queue_free()
		for i : int in range(0, len(buttons_text)):
			%Buttons.add_child(custom_button.instantiate())
			GeneralManager.disconnect_connections(%Buttons.get_child(-1).pressed)
			%Buttons.get_child(-1).pressed.connect(Callable(self, &"btn_pressed").bind(i))
			%Buttons.get_child(-1).text = " " + buttons_text[i] + " "
			%Buttons.get_child(-1).set(&"theme_override_font_sizes/font_size", 50)
var pressed_button : int = 0
signal button_pressed

func _ready() -> void:
	buttons_text = buttons_text
	return

func btn_pressed(btn : int) -> void:
	pressed_button = btn
	self.emit_signal(&"button_pressed")
	open = false
	return
