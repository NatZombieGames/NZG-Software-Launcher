extends VBoxContainer

const custom_button : PackedScene = preload("res://Scenes/CustomButton.tscn")
@onready var main : Control = $/root/Main
@export var product : APIManager.product = APIManager.product.UNKNOWN:
	set(value):
		product = value
		while self.get_child_count() > 1:
			self.get_child(-1).queue_free()
			await get_tree().process_frame
		for src : String in APIManager.product_to_source[product]:
			if src != "":
				self.add_child(custom_button.instantiate())
				self.get_child(-1).text = APIManager.api_to_api_name[APIManager.product_to_source[product].find(src)]
				self.get_child(-1).pressed.connect(func() -> void: OS.shell_open(src); return)
				self.get_child(-1).mouse_entered.connect(func() -> void: main.tooltip_txt = src; main.tooltip = true; return)
				self.get_child(-1).mouse_exited.connect(func() -> void: main.tooltip = false; return)
				self.get_child(-1).tooltip_text = src
		return
