extends Object
class_name ProductData

var product : APIManager.product
var installed : bool = false
var data : Dictionary[data_key, Variant] = {
	data_key.INSTALL_PATH: "", 
	data_key.VERSION: "", 
}
enum data_key {INSTALL_PATH, VERSION}

func _init(type : APIManager.product = APIManager.product.UNKNOWN) -> void:
	product = type
	return
