extends Control

var loading : bool = true:
	set(value):
		loading = value
		if loading:
			$Camera/ScreenContainer/LoadingScreen.visible = true
		else:
			await create_tween().tween_property($Camera/ScreenContainer/LoadingScreen, "modulate:a", 0, 0.15).from(1).finished
			$Camera/ScreenContainer/LoadingScreen.visible = false

# DONT FORGET TO CREDIT FOR THE FONT WHICH IS 'Ubuntu (Light)' FROM GOOGLE FONTS!!!!!!!!

func _ready() -> void:
	loading = true
	#
	$Camera/ScreenContainer/WindowButtons/DragWindowButton.button_down.connect(func() -> void:
		var starting_window_pos : Vector2i = DisplayServer.window_get_position()
		var starting_mouse_pos : Vector2i = DisplayServer.mouse_get_position()
		while $Camera/ScreenContainer/WindowButtons/DragWindowButton.button_pressed:
			DisplayServer.window_set_position(starting_window_pos + (DisplayServer.mouse_get_position() - starting_mouse_pos))
			DisplayServer.cursor_set_shape(DisplayServer.CURSOR_DRAG)
			await get_tree().process_frame
		return)
	if not IconLoader.finished_loading_icons:
		await IconLoader.finished_loading_icons_signal
	%SettingsButton.texture_normal = IconLoader.icons[&"Options"]
	%SettingsButton.pressed.connect(func() -> void: $Camera/ScreenContainer/PopupPage.open = true; return)
	%MinimizeButton.texture_normal = IconLoader.icons[&"Minimize"]
	%MinimizeButton.pressed.connect(func() -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED); return)
	%FullscreenButton.texture_normal = IconLoader.icons[&"Fullscreen"]
	%FullscreenButton.pressed.connect(
		func() -> void:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				return
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			return)
	%CloseButton.texture_normal = IconLoader.icons[&"Close"]
	%CloseButton.pressed.connect(Callable(self, &"_exit"))
	%MainContainer/SidePanel/VBoxContainer/TogglePageButton.texture_normal = IconLoader.icons[&"Downloaded"]
	%MainContainer/SidePanel/VBoxContainer/TogglePageButton.texture_pressed = IconLoader.icons[&"Products"]
	#
	loading = false
	return

func _exit() -> void:
	loading = true
	get_tree().quit()
	return
