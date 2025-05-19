extends VBoxContainer

func _ready() -> void:
	var open_app : APIManager.product = $/root/Main.open_app
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(APIManager.product.find_key(open_app), "").replace('"', "")
	$Reinstall.pressed.connect(Callable($/root/Main, &"initiate_download").bindv([
		location.get_file(), open_app, APIManager.get_available_api(open_app), 
		location.get_base_dir(), UserManager.platform]))
	return
