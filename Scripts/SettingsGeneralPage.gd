extends Control

func _ready() -> void:
	$Container/CloseOnOpenBtn.toggled.connect(func(state : bool) -> void: UserManager.settings[&"CloseOnAppLaunch"] = state; $Container/CloseOnOpenBtn.text = "Close Launcher On Launching Application " + ["☐", "🗹"][int(state)]; return)
	$Container/CloseOnOpenBtn.button_pressed = UserManager.settings[&"CloseOnAppLaunch"]
	return
