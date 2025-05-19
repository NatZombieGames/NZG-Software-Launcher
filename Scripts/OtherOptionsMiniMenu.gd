extends VBoxContainer

var minimenu : ColorRect

func _ready() -> void:
	var reopen : Callable = Callable($/root/Main, &"open_app_page").bind($/root/Main.open_app)
	var prod_key : String = APIManager.product.find_key($/root/Main.open_app)
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(prod_key, "").replace('"', "")
	$Delete.pressed.connect(
		func() -> void:
			OS.move_to_trash(location)
			UserManager.settings[&"ProductToInstallLocation"][prod_key] = ""
			reopen.call()
			minimenu.open = false
			return)
	$Move.pressed.connect(
		func() -> void:
			$FileDialog.visible = true
			await $FileDialog.file_selected
			DirAccess.rename_absolute(location, $FileDialog.current_path)
			UserManager.settings[&"ProductToInstallLocation"][prod_key] = $FileDialog.current_path
			reopen.call()
			minimenu.open = false
			return)
	$ChangeDestination.pressed.connect(
		func() -> void:
			$FileDialog.visible = true
			await $FileDialog.file_selected
			UserManager.settings[&"ProductToInstallLocation"][prod_key] = $FileDialog.current_path
			reopen.call()
			minimenu.open = false
			return)
	return
