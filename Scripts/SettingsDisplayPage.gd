extends Control

@onready var main : Control = $/root/Main
const tooltip_texts : PackedStringArray = [
	"If enabled then the icon for a given app is shown as the\nbackground when inside that app's page; On by default.", 
	"If enabled then while downloading additional information is show\nalongside showing a downloading indicator when any download\nis happening; Off by default.", 
	]

func _ready() -> void:
	$Container/ShowAppBackgroundBtn.toggled.connect(func(state : bool) -> void: UserManager.settings[&"ShowAppBackground"] = state; $Container/ShowAppBackgroundBtn.text = " Show App Background " + ["☐", "🗹"][int(state)] + " "; return)
	$Container/ShowAppBackgroundBtn.button_pressed = UserManager.settings[&"ShowAppBackground"]
	$Container/InfoForNerdsBtn.toggled.connect(func(state : bool) -> void: UserManager.settings[&"InfoForNerds"] = state; $Container/InfoForNerdsBtn.text = " Info For Nerds " + ["☐", "🗹"][int(state)] + " "; return)
	$Container/InfoForNerdsBtn.button_pressed = UserManager.settings[&"InfoForNerds"]
	$Container/ShowAppBackgroundBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[0]; main.tooltip = true; return)
	$Container/ShowAppBackgroundBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	$Container/InfoForNerdsBtn.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[1]; main.tooltip = true; return)
	$Container/InfoForNerdsBtn.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	return
