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
		while %Buttons.get_child_count() > len(buttons_text): %Buttons.get_child(-1).queue_free()
		while len(buttons_text) > %Buttons.get_child_count(): %Buttons.add_child(custom_button.instantiate())
		for btn : Button in %Buttons.get_children(): GeneralManager.disconnect_connections(btn.pressed)
		for i : int in range(0, %Buttons.get_child_count()): %Buttons.get_child(i).pressed.connect(Callable(self, &"btn_pressed").bind(i))
		for i : int in range(0, len(buttons_text)):
			%Buttons.get_child(i).text = " " + buttons_text[i] + " "
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
