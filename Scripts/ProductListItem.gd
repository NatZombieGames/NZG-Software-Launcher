extends PanelContainer

@export var product : APIManager.product = APIManager.product.UNKNOWN:
	set(value):
		product = value
		title = APIManager.product_to_name[product]
		categories.assign(APIManager.product_to_product_categories[product])
		categories = categories
		if APIManager.product_category.SOFTWARE in categories:
			subtitle = APIManager.product.find_key(product)
		else:
			subtitle = ""
		icon_path = "res://Assets/ProductAssets/Icons/" + APIManager.product.find_key(product) + "_Icon.png"
var title : String = "Nat Music Programme":
	set(value):
		title = value
		$Container/NameContainer/Container/Title.text = title
var subtitle : String = "NMP":
	set(value):
		subtitle = value
		if len(subtitle) > 0:
			$Container/NameContainer/Container/Subtitle.text = "(" + subtitle + ")"
		else:
			$Container/NameContainer/Container/Subtitle.text = ""
var icon_path : String = "res://Assets/ProductAssets/Icons/NMP_Icon.png":
	set(value):
		icon_path = value
		$Container/IconContainer/Icon.texture = load(value)
var categories : Array[APIManager.product_category] = []:
	set(value):
		categories = value
		$Container/CategoriesContainer/Categories.text = ""
		for category : APIManager.product_category in categories:
			$Container/CategoriesContainer/Categories.text += APIManager.product_category.find_key(category).capitalize() + ", "
		if len($Container/CategoriesContainer/Categories.text) > 0:
			$Container/CategoriesContainer/Categories.text = $Container/CategoriesContainer/Categories.text.left(-2)

func _ready() -> void:
	$Button.mouse_entered.connect(func() -> void: self.set(&"theme_override_styles/panel", ColourManager.styleboxes[&"ProductListItemHoveredStylebox"]); return)
	$Button.mouse_exited.connect(func() -> void: self.set(&"theme_override_styles/panel", ColourManager.styleboxes[&"ProductListItemStylebox"]); return)
	return
