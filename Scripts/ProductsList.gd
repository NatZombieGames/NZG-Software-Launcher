extends MarginContainer

const product_list_item : PackedScene = preload("res://Scenes/ProductListItem.tscn")
@export var title : String = "Category Name":
	set(value):
		title = value
		$Container/Title.text = title
@export var products : Array[APIManager.product] = []

func _ready() -> void:
	self.visibility_changed.connect(
		func() -> void:
			if self.is_visible_in_tree():
				for child : Node in %List.get_children(): child.visible = false
				await get_tree().create_timer(0.05).timeout
				for child : Node in %List.get_children():
					child.fade_in()
					await get_tree().create_timer(0.025).timeout
				return)
	return

func update_products_list() -> void:
	while %List.get_child_count() < len(products):
		%List.add_child(product_list_item.instantiate())
	for item : Control in %List.get_children(): item.visible = false
	var product : APIManager.product
	for i : int in range(0, len(products)):
		product = products[i]
		%List.get_child(i).product = product
		%List.get_child(i).visible = true
	return
