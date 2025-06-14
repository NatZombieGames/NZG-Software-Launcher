extends VBoxContainer

@onready var main : Control = $/root/Main
const tooltip_texts : PackedStringArray = [
	"If enabled then when exiting the programme\nthe 'Error Log' will always be written;\nOff by default.", 
	"Writes the current error log to a file in the 'NSLErrorLogs'\nfolder in the same directory as the programme;\ncreating this folder if it doesn't already exist.", 
	]

func _ready() -> void:
	$AlwaysWriteErrorLogButton.toggled.connect(func(state : bool) -> void: UserManager.settings[&"AlwaysWriteErrorLog"] = state; $AlwaysWriteErrorLogButton.text = " Write Error Log On Quit " + ["☐", "🗹"][int(state)] + " ")
	$AlwaysWriteErrorLogButton.button_pressed = UserManager.settings[&"AlwaysWriteErrorLog"]
	$AlwaysWriteErrorLogButton.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[0]; main.tooltip = true; return)
	$AlwaysWriteErrorLogButton.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	$WriteErrorLogButton.pressed.connect(func() -> void: $WriteNotifier.text = "Wrote Error Log to: '" + UserManager.write_error_log() + "'"; $WriteNotifier.visible = true; await get_tree().create_timer(2.5).timeout; $WriteNotifier.visible = false; return)
	$WriteErrorLogButton.mouse_entered.connect(func() -> void: main.tooltip_txt = tooltip_texts[1]; main.tooltip = true; return)
	$WriteErrorLogButton.mouse_exited.connect(func() -> void: main.tooltip = false; return)
	$WriteNotifier.visible = false
	return
