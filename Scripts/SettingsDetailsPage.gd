extends Control

@onready var main : Control = $/root/Main

func _ready() -> void:
	$Label.meta_hover_started.connect(func(txt : String) -> void: main.tooltip_txt = txt; main.tooltip = true; return)
	$Label.meta_hover_ended.connect(func(_txt : String) -> void: main.tooltip = false; return)
	$Label.meta_clicked.connect(func(txt : String) -> void: OS.shell_open(txt); return)
	return
