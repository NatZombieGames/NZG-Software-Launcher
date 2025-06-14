extends Node
##The manager for all the icon loading

##All the programmes icons to be used by other parts of the programme after it has been populated, when it is populated [member finished_loading_icons] will be set to [code]true[/code] and [signal finished_loading_icons_signal] will be emitted
var icons : Dictionary[StringName, ImageTexture]
##The icon for each [enum APIManager.product], populated at the same time as [member icons]
var product_icons : Dictionary[APIManager.product, ImageTexture] = {}
var finished_loading_icons : bool = false
signal finished_loading_icons_signal

func _init() -> void:
	for product : String in APIManager.product.keys():
		if product != "UNKNOWN":
			product_icons[APIManager.product[product]] = ImageTexture.create_from_image(load("res://Assets/ProductAssets/Icons/" + product + "_Icon.png").get_image())
	for icon : String in DirAccess.get_files_at("res://Assets/Icons"):
		if icon.get_extension() == "svg":
			icons[StringName(icon.get_basename())] = load_svg_to_img("res://Assets/Icons/" + icon, 2.0)
	finished_loading_icons = true
	self.emit_signal(&"finished_loading_icons_signal")
	return

##For the given .svg file returns an [ImageTexture] rendered at the given [param scale]
static func load_svg_to_img(svg_path : String, scale : float = 1.0) -> ImageTexture:
	# Code inspired from https://forum.godotengine.org/t/how-to-leverage-the-scalability-of-svg-in-godot/82292
	# But made for single-use instead.
	var bitmap : Image = Image.new()
	bitmap.load_svg_from_buffer(FileAccess.get_file_as_bytes(svg_path), scale)
	var texture : ImageTexture = ImageTexture.create_from_image(bitmap)
	texture.resource_name = svg_path.get_file().left(svg_path.get_file().find("."))
	return ImageTexture.create_from_image(bitmap)
