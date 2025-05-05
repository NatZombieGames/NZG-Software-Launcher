extends Control

const product_list : PackedScene = preload("res://Scenes/ProductsList.tscn")
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
	@warning_ignore("static_called_on_instance")
	%MainContainer/SidePanel/Container/ProductsPageButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/Products.svg", 3.0)
	%MainContainer/SidePanel/Container/ProductsPageButton.pressed.connect(func() -> void: %AppBody.visible = false; %ProductsBody.visible = true; %MainContainer/Body/Container/PageTitle.text = " Products Page"; return)
	$Camera/ScreenContainer/PopupPage.data.assign({&"Settings1": preload("res://Scenes/SettingsPage.tscn"), &"Settings2": preload("res://Scenes/SettingsPage.tscn")})
	$Camera/ScreenContainer/PopupPage.data = $Camera/ScreenContainer/PopupPage.data
	populate_products_page()
	%AppBody.visible = true
	%ProductsBody.visible = false
	#
	loading = false
	await get_tree().create_timer(0.5).timeout
	#initiate_download("testing.exe", APIManager.product.NMP, APIManager.api.ITCH, APIManager.info_types.EXECUTABLE_URL, OS.get_executable_path().get_base_dir())
	return

func populate_products_page() -> void:
	while %ProductsBody/ScrollContainer/Container.get_child_count() < len(APIManager.product_category.keys()):
		%ProductsBody/ScrollContainer/Container.add_child(product_list.instantiate())
	for category : String in APIManager.product_category.keys():
		%ProductsBody/ScrollContainer/Container.get_child(APIManager.product_category[category]).title = category.capitalize()
	for product : APIManager.product in APIManager.product_to_product_categories.keys():
		for category : APIManager.product_category in APIManager.product_to_product_categories[product]:
			%ProductsBody/ScrollContainer/Container.get_child(category).products.append(product)
			%ProductsBody/ScrollContainer/Container.get_child(category).update_products_list()
	return

func initiate_download(downloaded_file_name : String, product : APIManager.product, api : APIManager.api, info_type : APIManager.info_types, write_location : String = UserManager.user_settings[UserManager.setting_key.DefaultDownloadLocation], exec_type : APIManager.executable_types = APIManager.executable_types.WINDOWS) -> void:
	var info : APIManager.fetch_response = APIManager.fetch_response.new()
	var attempts : int = 0
	if APIManager.attempt_connection(api) != APIManager.connection_status.CONNECTED:
		%DownloadScreen.visible = false
		print("failed here :(")
		return
	while attempts < 2 and info.status != APIManager.fetch_status.RETRIEVED:
		info = APIManager.fetch_info(api, product, info_type, exec_type)
		info._get_details()
		attempts += 1
		await get_tree().create_timer(0.1).timeout
	if info.status != APIManager.fetch_status.RETRIEVED:
		%DownloadScreen.visible = false
		print("failed there :(")
		return
	var file : FileAccess = FileAccess.open(write_location + "/" + downloaded_file_name, FileAccess.WRITE)
	var buffer : PackedByteArray = await APIManager.download_executable(info.response, product, info.data, api)
	%DownloadScreen/Panel/Container/Title.text = "File Writing In Progress..."
	%DownloadScreen/Panel/Container/ProgressBar.value = 0.0
	file.store_buffer(buffer)
	%DownloadScreen/Panel/Container/ProgressBar.value = 0.5
	file.close()
	%DownloadScreen/Panel/Container/ProgressBar.value = 1.0
	await get_tree().process_frame
	%DownloadScreen.visible = false
	return

func update_download_visuals(target_name : String, version : String, platform : String, download_size : int, time_elapsed : float, progress : float) -> void:
	%DownloadScreen.visible = true
	%DownloadScreen/Panel/Container/Title.text = "Download In Progress..."
	%DownloadScreen/Panel/Container/Details/Name.text = target_name
	%DownloadScreen/Panel/Container/Details/Version.text = version
	%DownloadScreen/Panel/Container/Details/Platform.text = platform
	%DownloadScreen/Panel/Container/Details/Size.text = String.humanize_size(download_size)
	%DownloadScreen/Panel/Container/Time.text = "Time Elapsed: " + str(time_elapsed).left(str(time_elapsed).find(".") + 3) + " | Time To Completion Estimate: " + str(int(maxf(time_elapsed, 0.1) / maxf(progress, 0.1)))
	%DownloadScreen/Panel/Container/ProgressBar.value = progress
	return

func _exit() -> void:
	loading = true
	UserManager.save_data()
	APIManager.clean_up_clients()
	get_tree().quit()
	return
