extends VBoxContainer

var minimenu : ColorRect

func _ready() -> void:
	var reopen : Callable = Callable($"/root/Main", &"open_app_page").bind($"/root/Main".open_app)
	var open_app : APIManager.product = $/root/Main.open_app
	var prod_key : String = APIManager.product.find_key($"/root/Main".open_app)
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(prod_key, "").replace('"', "")
	$Reinstall.pressed.connect(Callable($/root/Main, &"initiate_download").bindv([
		location.get_file(), open_app, APIManager.get_available_api(open_app), 
		location.get_base_dir(), UserManager.platform]))
	$Delete.pressed.connect(
		func() -> void:
			if FileAccess.file_exists(location):
				OS.move_to_trash(location)
			UserManager.settings[&"ProductToInstallLocation"][prod_key] = ""
			reopen.call()
			minimenu.open = false
			return
			)
	return
