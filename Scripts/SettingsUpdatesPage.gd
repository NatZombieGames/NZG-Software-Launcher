extends VBoxContainer

@onready var main : Control = $/root/Main
const tooltip_texts : PackedStringArray = [
	"Sends a request to the launcher repository to get the info\nabout the latest release, such as the version number and size.", 
	"Updates your launcher to the latest version by first\ndownloading it and then launching the newly\ndownloaded version before deleting the old installation.", 
	"https://github.com/NatZombieGames/NZG-Software-Launcher", 
	]

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
	$GetLatestVersionBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[0]; main.tooltip = true; return)
	$GetLatestVersionBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	$UpdateBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[1]; main.tooltip = true; return)
	$UpdateBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	$SourceBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[2]; main.tooltip = true; return)
	$SourceBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
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
