extends VBoxContainer

func _ready() -> void:
	$GetLatestVersionBtn.pressed.connect(
		func() -> void:
			UpdateManager.get_latest_version_info()
			update()
			return
			)
	$UpdateBtn.pressed.connect(
		func() -> void:
			UpdateManager.download_latest_version()
			return
			)
	$SourceBtn.pressed.connect(func() -> void: OS.shell_open("https://github.com/NatZombieGames/NZG-Software-Launcher"); return)
	self.visibility_changed.connect(Callable(self, &"update"))
	update()
	return

func update() -> void:
	$CurVersion.text = "Current Version: " + UpdateManager.current_version
	$LatestVersion.text = "Latest Version: " + UpdateManager.latest_version
	$LatestVersionSize.text = "Latest Version Size: " + String.humanize_size(int(UpdateManager.latest_version_size))
	$GetLatestVersionBtn.visible = !UpdateManager.retrieved_latest_version_info
	$UpdateBtn.visible = UpdateManager.retrieved_latest_version_info and UpdateManager.current_version != UpdateManager.latest_version
	return
