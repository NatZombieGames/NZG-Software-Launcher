extends ColorRect

const custom_button : PackedScene = preload("res://Scenes/CustomButton.tscn")
const btn_group : ButtonGroup = preload("res://Assets/ButtonGroups/PopupPageTabsButtonGroup.tres")

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
var data : Dictionary[StringName, PackedScene]:
	set(value):
		data = value
		print("ran")
		for node : Control in %Tabs.get_children(): node.queue_free()
		for node : Control in %Body.get_children(): node.queue_free()
		for key : StringName in data.keys():
			%Tabs.add_child(custom_button.instantiate())
			%Tabs.get_child(-1).text = String(key)
			%Tabs.get_child(-1).button_group = btn_group
			%Tabs.get_child(-1).toggle_mode = true
			%Tabs.get_child(-1).pressed.connect(Callable(self, &"set_page").bind(data.keys().find(key)))
			%Body.add_child(data[key].instantiate())
		%Tabs.get_child(0).button_pressed = true

func _ready() -> void:
	if not IconLoader.finished_loading_icons:
		await IconLoader.finished_loading_icons_signal
	$Panel/Container/TabsContainer/CloseButton.texture_normal = IconLoader.icons[&"Close"]
	$Panel/Container/TabsContainer/CloseButton.pressed.connect(func() -> void: open = false; return)
	return

func set_page(page_num : int = 0) -> void:
	for node : Control in %Body.get_children(): node.visible = false
	if page_num >= %Body.get_child_count() or page_num < 0:
		page_num = 0
	%Body.get_child(page_num).visible = true
	return
