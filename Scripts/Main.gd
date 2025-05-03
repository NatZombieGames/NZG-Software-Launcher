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
	APIManager.main = self
	UserManager.load_data()
	var to_apply : Dictionary[StringName, Color]
	to_apply.assign(UserManager.user_settings[UserManager.setting_key.ColourSettings])
	ColourManager.apply_colour_settings(to_apply)
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
	@warning_ignore_start("static_called_on_instance")
	%MainContainer/SidePanel/VBoxContainer/TogglePageButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/Downloaded.svg", 3.0)
	%MainContainer/SidePanel/VBoxContainer/TogglePageButton.texture_pressed = IconLoader.load_svg_to_img("res://Assets/Icons/Products.svg", 3.0)
	@warning_ignore_restore("static_called_on_instance")
	$Camera/ScreenContainer/PopupPage.data.assign({&"Settings1": preload("res://Scenes/SettingsPage.tscn"), &"Settings2": preload("res://Scenes/SettingsPage.tscn")})
	$Camera/ScreenContainer/PopupPage.data = $Camera/ScreenContainer/PopupPage.data
	#
	loading = false
	#APIManager.attempt_connection(APIManager.api.GITHUB)
	#var info : APIManager.fetch_response = await APIManager.fetch_info(APIManager.api.GITHUB, APIManager.product.NMP, APIManager.info_types.EXECUTABLE_URL, APIManager.executable_types.WINDOWS)
	#info._get_details()
	#var file : FileAccess = FileAccess.open(OS.get_executable_path().get_base_dir() + "/is this nmp.exe", FileAccess.WRITE)
	#file.store_buffer(await APIManager.download_executable(info.response, APIManager.product.NPS))
	#file.close()
	return

func _exit() -> void:
	loading = true
	UserManager.save_data()
	APIManager.clean_up_clients()
	get_tree().quit()
	return
