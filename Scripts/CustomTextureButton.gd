extends PanelContainer

@export var pressed_callable : Callable
@export var button : TextureButton

func _ready() -> void:
	button = $Btn
	$Btn.mouse_entered.connect(func() -> void: self.set(&"theme_override_styles/panel", ColourManager.styleboxes[&"CustomButtonHoverStylebox"]); return)
	$Btn.mouse_exited.connect(func() -> void: self.set(&"theme_override_styles/panel", ColourManager.styleboxes[&"CustomButtonNormalStylebox"]); return)
	$Btn.pressed.connect(func() -> void: pressed_callable.call(); self.set(&"theme_override_styles/panel", ColourManager.styleboxes[&"CustomButtonPressedStylebox"]); await get_tree().create_timer(0.15).timeout; self.set(&"theme_override_styles/panel", ColourManager.styleboxes[&"CustomButtonNormalStylebox"]); return)
	return
