extends Control

func _ready() -> void:
	$Container/ShowAppBackgroundBtn.toggled.connect(func(state : bool) -> void: UserManager.settings[&"ShowAppBackground"] = state; $Container/ShowAppBackgroundBtn.text = "Show App Background " + ["☐", "🗹"][int(state)]; return)
	$Container/ShowAppBackgroundBtn.button_pressed = UserManager.settings[&"ShowAppBackground"]
	return
