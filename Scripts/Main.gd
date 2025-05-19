extends Control

const product_list : PackedScene = preload("res://Scenes/ProductsList.tscn")
const custom_texture_button : PackedScene = preload("res://Scenes/CustomTextureButton.tscn")
const install_options_mini_menu : PackedScene = preload("res://Scenes/InstallOptionsMiniMenu.tscn")
const other_options_mini_menu : PackedScene = preload("res://Scenes/OtherOptionsMiniMenu.tscn")
var loading : bool = true:
	set(value):
		loading = value
		if loading:
			$Camera/ScreenContainer/LoadingScreen.visible = true
		else:
			await create_tween().tween_property($Camera/ScreenContainer/LoadingScreen, "modulate:a", 0, 0.15).from(1).finished
			$Camera/ScreenContainer/LoadingScreen.visible = false
var soft_loading : bool = false:
	set(value):
		soft_loading = value
		$Camera/ScreenContainer/SoftLoadingScreen.visible = value
var open_app : APIManager.product = APIManager.product.UNKNOWN
var get_prod_shorts_callable : Callable = (func() -> Array[APIManager.product]: var prod_shorts : Array[APIManager.product]; prod_shorts.assign(UserManager.settings[&"ProductShortcuts"].map(func(item : String) -> APIManager.product: return APIManager.product[item])); return prod_shorts)

func _ready() -> void:
	loading = true
	await get_tree().process_frame
	#
	APIManager.main = self
	_handle_app_cli_args()
	UserManager.load_data()
	var to_apply : Dictionary[StringName, Color]
	to_apply.assign(UserManager.settings[&"ColourSettings"])
	ColourManager.apply_colour_settings(to_apply)
	$Camera/ScreenContainer/PopupPage.open = true
	%Header/Container/WindowButtons/DragWindowButton.button_down.connect(func() -> void:
		var starting_window_pos : Vector2i = DisplayServer.window_get_position()
		var starting_mouse_pos : Vector2i = DisplayServer.mouse_get_position()
		while %Header/Container/WindowButtons/DragWindowButton.button_pressed:
			DisplayServer.cursor_set_shape(DisplayServer.CURSOR_DRAG)
			DisplayServer.window_set_position(starting_window_pos + (DisplayServer.mouse_get_position() - starting_mouse_pos))
			await get_tree().process_frame
		return)
	if not IconLoader.finished_loading_icons:
		await IconLoader.finished_loading_icons_signal
	$Camera/ScreenContainer/SoftLoadingScreen/Container/Icon.texture = IconLoader.icons[&"LoadingIcon"]
	$Camera/ScreenContainer/LoadingScreen/Icon.texture = IconLoader.icons[&"LoadingIcon"]
	%SettingsButton.texture_normal = IconLoader.icons[&"Options"]
	%SettingsButton.pressed.connect(func() -> void: $Camera/ScreenContainer/PopupPage.open = true; return)
	var settings_script : GDScript = GDScript.new()
	settings_script.source_code = "extends TextureButton\nvar spd : float = 0.0\nfunc _init() -> void:\n\twhile true:\n\t\tawait get_tree().process_frame\n\t\tspd += (-0.001 + (0.01 * float(int(self.is_hovered()))))\n\t\tspd = clampf(spd, 0.0, 0.02)\n\t\tself.material.set('shader_parameter/rot', fposmod(self.material.get('shader_parameter/rot') + spd, 1.0))\n\treturn\n"
	settings_script.reload()
	%SettingsButton.set_script(settings_script)
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
	%AppBody/Container/ScrollBar.value_changed.connect(
		func(value : float) -> void: 
			%AppBody/Background.material.set(&"shader_parameter/scroll_progress", 0.0)
			%AppContent.position.y = 0.0
			if %AppContent.size.y > %AppBody/Container/ContentContainer.size.y:
				%AppBody/Background.material.set(&"shader_parameter/scroll_progress", value)
				%AppContent.position.y = ((%AppContent.size.y - %AppBody/Container/ContentContainer.size.y) * value) * -1.0
			return)
	@warning_ignore("static_called_on_instance")
	%MainContainer/SidePanel/Container/ProductsPageButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/Products.svg", 3.0)
	%MainContainer/SidePanel/Container/ProductsPageButton.pressed.connect(func() -> void: %AppBody.visible = false; %ProductsBody.visible = true; %Header/Container/PageTitle.text = "  Products"; return)
	$Camera/ScreenContainer/PopupPage.data.assign({&"Theme Settings": preload("res://Scenes/SettingsThemePage.tscn"), &"Details": preload("res://Scenes/DetailsPage.tscn")})
	$Camera/ScreenContainer/PopupPage.data = $Camera/ScreenContainer/PopupPage.data
	%AppContent/ActionButtonsContainer/LaunchButton.pressed.connect(Callable(self, &"app_button_pressed").bind(0))
	%AppContent/ActionButtonsContainer/UpdateButton.pressed.connect(Callable(self, &"app_button_pressed").bind(1))
	%AppContent/ActionButtonsContainer/SourceButton.pressed.connect(Callable(self, &"app_button_pressed").bind(2))
	%AppContent/ActionButtonsContainer/InstallOptionsButton.pressed.connect(Callable(self, &"app_button_pressed").bind(3))
	%AppContent/ActionButtonsContainer/OtherOptionsButton.pressed.connect(Callable(self, &"app_button_pressed").bind(4))
	%AppContent/ActionButtonsContainer/PointButton.pressed.connect(Callable(self, &"app_button_pressed").bind(5))
	populate_products_page()
	$Camera/ScreenContainer/ConfirmationDialog.visible = false
	%DownloadScreen.visible = false
	%AppBody.visible = false
	%ProductsBody.visible = true
	$Camera/ScreenContainer/MiniMenu.open = false
	populate_shortcut_list()
	soft_loading = false
	$Camera/ScreenContainer/PopupPage.open = false
	#
	loading = false
	#await get_tree().create_timer(5.5).timeout
	#initiate_download("testing.exe", APIManager.product.NMP, APIManager.api.GITHUB, OS.get_executable_path().get_base_dir(), APIManager.platforms.LINUX)
	return

func _input(event: InputEvent) -> void:
	if event.get_class() in ["InputEventMouseMotion", "InputEventMouseButton"]:
		return
	var prod_shorts : Array[APIManager.product] = get_prod_shorts_callable.call()
	for i : int in range(0, 10):
		if i > len(prod_shorts):
			break
		if event.is_action_pressed(StringName("AppShortcut" + str(i+1)), false, true):
			open_app_page(prod_shorts[i])
			break
	return

func _handle_app_cli_args() -> void:
	var args : Dictionary[String, Variant] = {}
	var split_arg : PackedStringArray
	for arg : String in OS.get_cmdline_args():
		arg = arg.right(-2)
		if "=" in arg and len(arg.replace("=", "")) > 1:
			split_arg = arg.split("=", false)
			args[split_arg[0]] = split_arg[1]
	#
	if "kill_old_nsl_process" in args.keys():
		OS.kill(args["kill_old_nsl_process"].split("|", false)[0])
		DirAccess.remove_absolute(args["kill_old_nsl_process"].split("|", false)[1])
	return

func app_button_pressed(button : int) -> void:
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(APIManager.product.find_key(open_app), "").replace('"', "")
	print("---\nbtn: ", button, "\nloc during app btn pressed:\n'" + location + "'\n---")
	var overwrite_callable : Callable = Callable(self, &"initiate_download").bindv([
		location.get_file(), open_app, 
		APIManager.get_available_api(open_app), 
		location.get_base_dir(), UserManager.platform])
	match button:
		0:
			match %AppContent/ActionButtonsContainer/LaunchButton.get_meta("FileTargetState", 0):
				0:
					%PickInstallLocationDialog.visible = true
					await %PickInstallLocationDialog.dir_selected
					var file_name : String = APIManager.product_to_name[open_app].replace(" ", "")
					if UserManager.platform == APIManager.platforms.WINDOWS:
						file_name += ".exe"
					UserManager.settings[&"ProductToInstallLocation"][APIManager.product.find_key(open_app)] = %PickInstallLocationDialog.current_path + "\\" + file_name
					print("file name: ", file_name, "\nselected folder: ", %PickInstallLocationDialog.current_path, "\nnew path: ", UserManager.settings[&"ProductToInstallLocation"][APIManager.product.find_key(open_app)])
					await initiate_download(
						file_name, open_app, 
						APIManager.get_available_api(open_app), 
						%PickInstallLocationDialog.current_path, UserManager.platform)
					print("here")
					open_app_page(open_app)
				1:
					overwrite_callable.call()
				2:
					OS.shell_open(location)
		1:
			overwrite_callable.call()
		2:
			print(location.get_base_dir())
			OS.shell_show_in_file_manager(location.get_base_dir(), true)
		3:
			open_mini_menu("Install Options", install_options_mini_menu)
		4:
			open_mini_menu("Other Options", other_options_mini_menu)
		5:
			%PointToExecutableDialog.visible = true
			await %PointToExecutableDialog.file_selected
			UserManager.settings[&"ProductToInstallLocation"][APIManager.product.find_key(open_app)] = %PointToExecutableDialog.current_path
			open_app_page(open_app)
	return

func open_app_page(app : APIManager.product) -> void:
	soft_loading = true
	await get_tree().create_timer(0.05).timeout
	#
	open_app = app
	UserManager.settings[&"ProductShortcuts"].erase(APIManager.product.find_key(app))
	UserManager.settings[&"ProductShortcuts"].insert(0, APIManager.product.find_key(app))
	%Header/Container/PageTitle.text = "  App"
	%AppBody/Background.texture = IconLoader.product_icons[app]
	%AppContent/AppName.text = "   " + APIManager.product_to_name[app]
	%AppContent/AppAcronym.text = ""
	if APIManager.product_category.SOFTWARE in APIManager.product_to_product_categories[app]:
		%AppContent/AppAcronym.text = "       (" + APIManager.product.find_key(app) + ")"
	%AppContent/InfoGreaterContainer/InfoContainer/InfoLabel.text = "Info:"
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(APIManager.product.find_key(open_app), "").replace('"', "")
	var app_info : Dictionary[String, String] = {
		"Name": APIManager.product_to_name[app], 
		"Categories": str(Array(APIManager.product_to_product_categories[app]).map(func(item : APIManager.product_category) -> String: return APIManager.product_category.find_key(item).capitalize())).replace('"', ""), 
		"Location": location, 
		"Location Valid": str(len(location.replace(" ", "")) > 0 and FileAccess.file_exists(location)).capitalize(), 
		"Executable": "", 
		"Up To Date": "",
		"Installed Version": "", 
		"Latest Version": "", 
		}
	var installed : bool = app_info["Location Valid"].to_lower() == "true"
	var up_to_date : bool = false
	app_info["Executable"] = "False"
	if installed:
		const platform_to_buffer_size : PackedInt32Array = [0, 2, 4]
		var buffer : PackedByteArray = FileAccess.open(location, FileAccess.READ).get_buffer(platform_to_buffer_size[UserManager.platform])
		if len(buffer) == platform_to_buffer_size[UserManager.platform]:
			match UserManager.platform:
				APIManager.platforms.WINDOWS:
					app_info["Executable"] = str((buffer[0] == 0x4d and buffer[1] == 0x5a) and location.get_extension() == "exe").capitalize()
				APIManager.platforms.LINUX:
					app_info["Executable"] = str(GeneralManager.mass_equal(buffer, [0x45, 0x4c, 0x46])).capitalize()
	var available_api : APIManager.api = APIManager.get_available_api(open_app)
	if not APIManager.connection_statuses[available_api] == APIManager.connection_status.CONNECTED:
		APIManager.attempt_connection(available_api)
	print("here")
	var latest_version_fetch : APIManager.fetch_response = APIManager.fetch_response.new(APIManager.fetch_status.RETRIEVED, APIManager.info_types.LATEST_VERSION, "1.0.4")#APIManager.fetch_info(available_api, open_app, APIManager.info_types.LATEST_VERSION)
	latest_version_fetch._get_details()
	if latest_version_fetch.status == APIManager.fetch_status.RETRIEVED:
		app_info["Latest Version"] = latest_version_fetch.response
		match UserManager.platform:
			APIManager.platforms.WINDOWS:
				app_info["Latest Version"] = GeneralManager.version_to_windows_version(app_info["Latest Version"])
				if FileAccess.file_exists(location):
					var out : Array[Variant]
					var cmd : String = '(Get-Item "' + location.replace("/", "\\") + '").VersionInfo.FileVersion'
					OS.execute("powershell.exe", ["-encodedcommand", Marshalls.raw_to_base64(cmd.to_utf16_buffer())], out, true)
					app_info["Installed Version"] = out[0].replace("\r", "").replace("\n", "").replace(" CLIXML", "").get_slice("<", 1)
					if app_info["Installed Version"].replace(" ", "") == "":
						app_info["Installed Version"] = "Unknown - Unknown error / exception happened."
				else:
					app_info["Installed Version"] = "Unknown - Can not retrieve installed version for destined path."
			APIManager.platforms.LINUX:
				if FileAccess.file_exists(location):
					var out : Array[Variant] = []
					OS.execute("file", ["-c", location], out, true)
					print(out)
					print(out[-2])
					# I dont use linux so I cant test this so I have this here,
					# someone else can hopefully make this work, i think this is kinda right maybe
					app_info["Installed Version"] = "Unknown - Can not retrieve installed version on Linux platforms."
				else:
					app_info["Installed Version"] = "Unknown - Can not retrieve installed version for destined path."
		up_to_date = app_info["Latest Version"] == app_info["Installed Version"]
	app_info["Up To Date"] = str(up_to_date).capitalize()
	for key : String in app_info:
		%AppContent/InfoGreaterContainer/InfoContainer/InfoLabel.text += "\n    " + key + ": " + app_info[key]
	%AppContent/ActionButtonsContainer/LaunchButton.set_meta("FileTargetState", int(installed) + int(app_info["Executable"].to_lower() == "true"))
	%AppContent/ActionButtonsContainer/LaunchButton.text = [" Install ", " Repair ", " Launch "][%AppContent/ActionButtonsContainer/LaunchButton.get_meta("FileTargetState", 0)]
	%AppContent/ActionButtonsContainer/UpdateButton.visible = !up_to_date and installed
	%AppContent/ActionButtonsContainer/SourceButton.visible = len(location.replace(" ", "")) > 0 and (location.is_absolute_path())
	%AppContent/ActionButtonsContainer/InstallOptionsButton.visible = installed
	%AppContent/ActionButtonsContainer/OtherOptionsButton.visible = installed
	%AppContent/ActionButtonsContainer/PointButton.visible = !installed
	%AppBody.visible = true
	%ProductsBody.visible = false
	populate_shortcut_list()
	#
	soft_loading = false
	return

func populate_shortcut_list() -> void:
	var prod_shorts : Array[APIManager.product] = get_prod_shorts_callable.call()
	prod_shorts.reverse()
	while %ShortcutList.get_child_count() < len(prod_shorts):
		%ShortcutList.add_child(custom_texture_button.instantiate())
	for child : Control in %ShortcutList.get_children(): child.visible = false
	for i : int in range(0, len(prod_shorts)):
		%ShortcutList.get_child(i).button.texture_normal = IconLoader.product_icons[prod_shorts[i]]
		%ShortcutList.get_child(i).pressed_callable = Callable(self, &"open_app_page").bind(prod_shorts[i])
		%ShortcutList.get_child(i).visible = true
	await get_tree().process_frame
	for child : Control in %ShortcutList.get_children(): child.custom_minimum_size.y = child.size.x
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

func initiate_download(downloaded_file_name : String, product : APIManager.product, api : APIManager.api, write_location : String = UserManager.settings[&"DefaultDownloadLocation"], exec_type : APIManager.platforms = APIManager.platforms.WINDOWS) -> void:
	print("initiating download")
	var info : APIManager.fetch_response = APIManager.fetch_response.new()
	var attempts : int = 0
	if APIManager.attempt_connection(api) != APIManager.connection_status.CONNECTED:
		%DownloadScreen.visible = false
		print("failed here :(")
		return
	while attempts < 2 and info.status != APIManager.fetch_status.RETRIEVED:
		info = APIManager.fetch_info(api, product, APIManager.info_types.EXECUTABLE_URL, exec_type)
		info._get_details()
		attempts += 1
		await get_tree().create_timer(0.1).timeout
	if info.status != APIManager.fetch_status.RETRIEVED:
		%DownloadScreen.visible = false
		print("failed there :(")
		return
	%DownloadScreen/Panel/Container/Title.text = "Download In Progress..."
	await GeneralManager.open_background_and_panel(true, %DownloadScreen, %DownloadScreen/Panel)
	var file : FileAccess = FileAccess.open(write_location + "/" + downloaded_file_name, FileAccess.WRITE)
	var buffer : PackedByteArray = await APIManager.download_executable(info.response, product, info.data, api)
	%DownloadScreen/Panel/Container/Title.text = "File Writing In Progress..."
	%DownloadScreen/Panel/Container/ProgressBar.value = 0.0
	file.store_buffer(buffer)
	%DownloadScreen/Panel/Container/ProgressBar.value = 0.5
	file.close()
	%DownloadScreen/Panel/Container/ProgressBar.value = 1.0
	await get_tree().process_frame
	GeneralManager.open_background_and_panel(false, %DownloadScreen, %DownloadScreen/Panel)
	return

func update_download_visuals(target_name : String, version : String, platform : String, api : String, download_size : int, time_elapsed : float, progress : int) -> void:
	%DownloadScreen/Panel/Container/Title.text = "Download In Progress" + "".lpad((int(Engine.get_frames_drawn() / 10.0) % 3) + 1, ".")
	var percentage : float = float(progress) / float(download_size)
	%DownloadScreen/Panel/Container/AppDetails/Name.text = target_name
	%DownloadScreen/Panel/Container/AppDetails/Version.text = "V" + version
	%DownloadScreen/Panel/Container/AppDetails/Platform.text = platform.capitalize() + " Build"
	%DownloadScreen/Panel/Container/DownloadDetails/API.text = "From: " + api.capitalize()
	%DownloadScreen/Panel/Container/Time.text = "Time Elapsed: " + str(time_elapsed).left(str(time_elapsed).find(".") + 3) + "s\nTime To Completion Estimate: " + str(int(maxf(time_elapsed, 0.1) / maxf(percentage, 0.1))) + "s"
	%DownloadScreen/Panel/Container/ProgressBar.value = percentage
	%DownloadScreen/Panel/Container/Size.text = String.humanize_size(progress) + "/" + String.humanize_size(download_size)
	return

func open_mini_menu(title : String, menu_scene : PackedScene) -> void:
	$Camera/ScreenContainer/MiniMenu.title = title
	$Camera/ScreenContainer/MiniMenu.page = menu_scene
	$Camera/ScreenContainer/MiniMenu.open = true
	return

func get_confirmation(text : String, buttons_text : PackedStringArray = ["No", "Yes"]) -> int:
	$Camera/ScreenContainer/ConfirmationDialog.text = text
	$Camera/ScreenContainer/ConfirmationDialog.buttons_text = buttons_text
	$Camera/ScreenContainer/ConfirmationDialog.open = true
	await $Camera/ScreenContainer/ConfirmationDialog.button_pressed
	return $Camera/ScreenContainer/ConfirmationDialog.pressed_btn

func _exit() -> void:
	loading = true
	UserManager.save_data()
	APIManager.clean_up_clients()
	get_tree().quit()
	return
