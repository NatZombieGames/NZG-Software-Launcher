extends ColorRect

@export var open : bool = false:
	set(value):
		open = value
		GeneralManager.open_background_and_panel(value, self, $Panel)
@export var title : String = "MiniMenu":
	set(value):
		title = value
		$Panel/Container/TabsContainer/Title.text = title
var page : PackedScene:
	set(value):
		if page != value:
			print("running :)")
			page = value
			for child : Node in %Body.get_children(): child.queue_free()
			%Body.add_child(page.instantiate())
			%Body.get_child(-1).minimenu = self

func _ready() -> void:
	if not IconLoader.finished_loading_icons:
		await IconLoader.finished_loading_icons_signal
	$Panel/Container/TabsContainer/CloseButton.texture_normal = IconLoader.icons[&"Close"]
	$Panel/Container/TabsContainer/CloseButton.pressed.connect(func() -> void: open = false; return)
	return
