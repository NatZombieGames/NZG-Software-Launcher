extends VBoxContainer

const custom_button : PackedScene = preload("res://Scenes/CustomButton.tscn")
##var minimenu : ColorRect # just here since the minimenu assumes we have this variable
@export var product : APIManager.product = APIManager.product.UNKNOWN:
	set(value):
		product = value
		while self.get_child_count() > 1:
			self.get_child(-1).queue_free()
			await get_tree().process_frame
		print(product, ", ", APIManager.product_to_source[product])
		for src : String in APIManager.product_to_source[product]:
			if src != "":
				self.add_child(custom_button.instantiate())
				self.get_child(-1).text = APIManager.api_to_api_name[APIManager.product_to_source[product].find(src)]
				self.get_child(-1).pressed.connect(func() -> void: OS.shell_open(src); return)
				self.get_child(-1).tooltip_text = src

func _ready() -> void:
	product = product
	return
