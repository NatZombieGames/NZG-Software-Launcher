extends ColorRect

var open : bool = false:
	set(value):
		open = value
		if open:
			self.visible = true
			create_tween().tween_property(self, "modulate:a", 1, 0.15).from(0)
			create_tween().tween_property($Panel, "modulate:a", 1, 0.15).from(0)
			create_tween().tween_property($Panel, "position:y", 135, 0.15).from(170)
		else:
			create_tween().tween_property(self, "modulate:a", 0, 0.15).from(1)
			create_tween().tween_property($Panel, "modulate:a", 0, 0.15).from(1)
			await create_tween().tween_property($Panel, "position:y", 100, 0.15).from(135).finished
			self.visible = false

func _ready() -> void:
	if not IconLoader.finished_loading_icons:
		await IconLoader.finished_loading_icons_signal
	$Panel/Container/TabsContainer/CloseButton.texture_normal = IconLoader.icons[&"Close"]
	$Panel/Container/TabsContainer/CloseButton.pressed.connect(func() -> void: open = false; return)
	return
