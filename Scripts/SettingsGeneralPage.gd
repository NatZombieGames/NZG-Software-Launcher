extends Control

@onready var main : Control = $/root/Main
const tooltip_texts : PackedStringArray = [
	"If enabled then when launching an application the\nlauncher will close itself after saving your data;\nOff by default.", 
	"Reopens the tutorial.", 
	]

func _ready() -> void:
	$Container/CloseOnOpenBtn.toggled.connect(func(state : bool) -> void: UserManager.settings[&"CloseOnAppLaunch"] = state; $Container/CloseOnOpenBtn.text = "Close Launcher On Launching Application " + ["☐", "🗹"][int(state)]; return)
	$Container/CloseOnOpenBtn.button_pressed = UserManager.settings[&"CloseOnAppLaunch"]
	$Container/CloseOnOpenBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[0]; main.tooltip = true; return)
	$Container/CloseOnOpenBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	$Container/OpenTutorialBtn.pressed.connect(func() -> void: main.tutorial = true; return)
	$Container/OpenTutorialBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[1]; main.tooltip = true; return)
	$Container/OpenTutorialBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	return
