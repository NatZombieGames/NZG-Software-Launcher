extends Control

const product_list : PackedScene = preload("res://Scenes/ProductsList.tscn")
const custom_texture_button : PackedScene = preload("res://Scenes/CustomTextureButton.tscn")
const install_options_mini_menu : PackedScene = preload("res://Scenes/InstallOptionsMiniMenu.tscn")
const other_options_mini_menu : PackedScene = preload("res://Scenes/OtherOptionsMiniMenu.tscn")
const source_mini_menu : PackedScene = preload("res://Scenes/SourceMiniMenu.tscn")
const alert_scene : PackedScene = preload("res://Scenes/Alert.tscn")
@onready var download_icon : TextureButton = %DownloadIcon
@onready var download_icon_material : ShaderMaterial = download_icon.material
@onready var download_icon_separator : Panel = download_icon.get_parent().get_child(2)
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
var downloading : bool = false:
	set(value):
		downloading = value
		if UserManager.settings[&"InfoForNerds"]:
			download_icon.set_deferred(&"visible", downloading)
			download_icon_separator.set_deferred(&"visible", downloading)
			while downloading:
				APIManager.mutexes[APIManager.mutex_type.DOWNLOAD_PROGRESS].lock()
				APIManager.mutexes[APIManager.mutex_type.DOWNLOAD_SIZE].lock()
				download_icon_material.set_deferred(&"shader_parameter/progress", float(APIManager.download_progress) / float(APIManager.download_size))
				APIManager.mutexes[APIManager.mutex_type.DOWNLOAD_PROGRESS].unlock()
				APIManager.mutexes[APIManager.mutex_type.DOWNLOAD_SIZE].unlock()
				await get_tree().process_frame
var downloading_mutex : Mutex = Mutex.new()
var open_app : APIManager.product = APIManager.product.UNKNOWN
var get_prod_shorts_callable : Callable = (func() -> Array[APIManager.product]: var prod_shorts : Array[APIManager.product]; prod_shorts.assign(UserManager.settings[&"ProductShortcuts"].map(func(item : String) -> APIManager.product: return APIManager.product[item])); return prod_shorts)
const settings_page_data : Dictionary[StringName, PackedScene] = {
	&"General Settings": preload("res://Scenes/SettingsGeneralPage.tscn"), 
	&"Display Settings": preload("res://Scenes/SettingsDisplayPage.tscn"), 
	&"API Keys": preload("res://Scenes/SettingsApiPage.tscn"), 
	&"Theme Settings": preload("res://Scenes/SettingsThemePage.tscn"), 
	&"Updates": preload("res://Scenes/SettingsUpdatesPage.tscn"), 
	&"Details": preload("res://Scenes/SettingsDetailsPage.tscn")
	}

func _ready() -> void:
	loading = true
	await get_tree().process_frame
	#
	@warning_ignore_start("static_called_on_instance")
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
	%DownloadIcon.texture_normal = IconLoader.icons[&"Download"]
	%DownloadIcon.pressed.connect(func() -> void: return)
	%DownloadIcon.visible = false
	%"DownloadIcon/../Void1".visible = false
	%SettingsButton.texture_normal = IconLoader.icons[&"Options"]
	%SettingsButton.pressed.connect(func() -> void: $Camera/ScreenContainer/PopupPage.open = true; return)
	%SettingsButton.set_script(GeneralManager.create_gdscript("extends TextureButton\nvar spd : float = 0.0\nfunc _init() -> void:\n\twhile true:\n\t\tawait get_tree().process_frame\n\t\tspd += (-0.001 + (0.01 * float(int(self.is_hovered()))))\n\t\tspd = clampf(spd, 0.0, 0.02)\n\t\tself.material.set('shader_parameter/rot', fposmod(self.material.get('shader_parameter/rot') + spd, 1.0))\n\treturn\n"))
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
	%MainContainer/SidePanel/Container/SocialsButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/Social.svg", 3.0)
	%MainContainer/SidePanel/Container/SocialsButton.toggled.connect(func(state : bool) -> void: GeneralManager.open_panel_and_container(state, %SocialsPopup, %SocialsPopup/Container); return)
	%MainContainer/SidePanel/Container/SocialsButton.set_script(GeneralManager.create_gdscript(
		"extends TextureButton\nfunc _init() -> void:\n\twhile true:\n\t\tawait get_tree().process_frame\n\t\tif self.global_position.distance_to(get_global_mouse_position()) > 400 and self.button_pressed == true:\n\t\t\tself.button_pressed = false\n\treturn"
		))
	%MainContainer/SidePanel/Container/AlertButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/AlertRinging.svg", 3.0)
	%MainContainer/SidePanel/Container/AlertButton.texture_hover = IconLoader.load_svg_to_img("res://Assets/Icons/AlertHovered.svg", 3.0)
	%MainContainer/SidePanel/Container/AlertButton.texture_pressed = IconLoader.load_svg_to_img("res://Assets/Icons/AlertAcknowledged.svg", 3.0)
	%MainContainer/SidePanel/Container/AlertButton.button_up.connect(
		func() -> void:
			if not %MainContainer/SidePanel/Container/AlertButton.get_meta(&"BeenPressed", false):
				%MainContainer/SidePanel/Container/AlertButton.set_meta(&"BeenPressed", true)
				var texture : ImageTexture = IconLoader.load_svg_to_img("res://Assets/Icons/AlertAcknowledged.svg", 3.0)
				%MainContainer/SidePanel/Container/AlertButton.texture_normal = texture
				%MainContainer/SidePanel/Container/AlertButton.texture_hover = texture
				%MainContainer/SidePanel/Container/AlertButton.texture_pressed = texture
			return)
	%MainContainer/SidePanel/Container/AlertButton.toggled.connect(func(state : bool) -> void: GeneralManager.open_panel_and_container(state, %AlertPopup, %AlertPopup/Container); return)
	%MainContainer/SidePanel/Container/AlertButton.set_script(GeneralManager.create_gdscript(
		"extends TextureButton\nvar spd : float = 0.15\nfunc _init() -> void:\n\twhile not self.get_meta(&'BeenPressed', false):\n\t\tawait create_tween().tween_property(self.material, 'shader_parameter/rot', 0.0, spd).from(1.0).set_ease(Tween.EASE_OUT_IN).finished\n\t\tawait create_tween().tween_property(self.material, 'shader_parameter/rot', 1.0, spd).from(0.0).set_ease(Tween.EASE_OUT_IN).finished\n\tself.material.set('shader_parameter/rot', 0.574)\n\treturn"
		))
	%AlertPopup/Container/Container/ActionButton.pressed.connect(func() -> void: $Camera/ScreenContainer/PopupPage.set_page(settings_page_data.keys().find(&"Updates")); $Camera/ScreenContainer/PopupPage.open = true; %MainContainer/SidePanel/Container/AlertButton.button_pressed = false; return)
	%MainContainer/SidePanel/Container/ProductsPageButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/Products.svg", 3.0)
	%MainContainer/SidePanel/Container/ProductsPageButton.pressed.connect(func() -> void: %AppBody.visible = false; %ProductsBody.visible = true; %Header/Container/PageTitle.text = "  Products"; return)
	$Camera/ScreenContainer/PopupPage.data.assign(settings_page_data)
	$Camera/ScreenContainer/PopupPage.data = $Camera/ScreenContainer/PopupPage.data
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/LaunchButton.pressed.connect(Callable(self, &"app_button_pressed").bind(0))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/UpdateButton.pressed.connect(Callable(self, &"app_button_pressed").bind(1))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/SourceButton.pressed.connect(Callable(self, &"app_button_pressed").bind(2))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/InstallOptionsButton.pressed.connect(Callable(self, &"app_button_pressed").bind(3))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/OtherOptionsButton.pressed.connect(Callable(self, &"app_button_pressed").bind(4))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/PointButton.pressed.connect(Callable(self, &"app_button_pressed").bind(5))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/WebSourceButton.pressed.connect(Callable(self, &"app_button_pressed").bind(6))
	populate_products_page()
	$Camera/ScreenContainer/ConfirmationDialog.visible = false
	%DownloadScreen.visible = false
	%AppBody.visible = false
	%ProductsBody.visible = true
	$Camera/ScreenContainer/MiniMenu.open = false
	populate_shortcut_list()
	soft_loading = false
	$Camera/ScreenContainer/PopupPage.open = false
	%SocialsPopup.visible = false
	%AlertPopup.visible = false
	UpdateManager.main = self
	UpdateManager.get_latest_version_info()
	%MainContainer/SidePanel/Container/AlertButton.visible = UpdateManager.retrieved_latest_version_info and UpdateManager.latest_version != UpdateManager.current_version
	@warning_ignore_restore("static_called_on_instance")
	#
	loading = false
	await get_tree().create_timer(0.2).timeout
	if %MainContainer/SidePanel/Container/AlertButton.visible:
		create_alert("Update Available", "Your app version " + UpdateManager.current_version + " does not match\nthe latest version of " + UpdateManager.latest_version + ".\nYou can download the update in the\nsettings menu under the 'Updates' page.")
	elif not UpdateManager.retrieved_latest_version_info:
		create_alert("Update Error", "Unable to check for the latest app version\nyou can check again by restarting the app or in the\nsettings in the 'Updates' page.")
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
		if "=" in arg and len(arg.replace("=", "")) > 1:
			split_arg = arg.split("=", false)
			args[split_arg[0]] = split_arg[1]
	_report_failure("Main Notification", "Cli args during app launch", {"os_args": OS.get_cmdline_args(), "user_args": OS.get_cmdline_user_args(), "keys": args.keys(), "values": args.values()})
	#
	if "kill_old_nsl_process" in args.keys():
		await get_tree().create_timer(0.1).timeout
		DirAccess.remove_absolute(args["kill_old_nsl_process"])
		await get_tree().create_timer(0.1).timeout
		DirAccess.rename_absolute(OS.get_executable_path(), args["kill_old_nsl_process"].get_file())
	return

func app_button_pressed(button : int) -> void:
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(APIManager.product.find_key(open_app), "").replace('"', "")
	print("---\nbtn: ", button, "\nloc during app btn pressed:\n'" + location + "'\n---")
	var overwrite_callable : Callable = Callable(self, &"initiate_download").bindv([
		location.get_file(), open_app, location.get_base_dir()])
	match button:
		0:
			match %AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/LaunchButton.get_meta("FileTargetState", 0):
				0:
					%PickInstallLocationDialog.visible = true
					await %PickInstallLocationDialog.dir_selected
					var file_name : String = APIManager.product_to_name[open_app].replace(" ", "")
					if UserManager.platform == APIManager.platforms.WINDOWS:
						file_name += ".exe"
					UserManager.settings[&"ProductToInstallLocation"][APIManager.product.find_key(open_app)] = %PickInstallLocationDialog.current_path + "\\" + file_name
					print("file name: ", file_name, "\nselected folder: ", %PickInstallLocationDialog.current_path, "\nnew path: ", UserManager.settings[&"ProductToInstallLocation"][APIManager.product.find_key(open_app)])
					await initiate_download(file_name, open_app, %PickInstallLocationDialog.current_path)
					print("here")
					open_app_page(open_app)
				1:
					overwrite_callable.call()
				2:
					loading = true
					await get_tree().process_frame
					OS.shell_open(location)
					if UserManager.settings[&"CloseOnAppLaunch"]:
						UserManager.save_data()
						get_tree().quit()
					loading = false
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
		6:
			print(open_app, ", ", APIManager.product_to_name[open_app])
			open_mini_menu("Source Locations", source_mini_menu, {&"product": open_app})
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
	%AppBody/Background.visible = UserManager.settings[&"ShowAppBackground"]
	%AppContent/AppName.text = "   " + APIManager.product_to_name[app]
	%AppContent/AppAcronym.text = ""
	if APIManager.product_category.SOFTWARE in APIManager.product_to_product_categories[app]:
		%AppContent/AppAcronym.text = "       (" + APIManager.product.find_key(app) + ")"
	%AppContent/InfoGreaterContainer/InfoContainer/InfoLabel.text = "Info:"
	var location : String = UserManager.settings[&"ProductToInstallLocation"].get(APIManager.product.find_key(open_app), "").replace('"', "")
	var app_info : Dictionary[String, String] = {
		"Name": APIManager.product_to_name[app], 
		"Categories": "", 
		"Location": location, 
		"Location Valid": "", 
		"Executable": "False", 
		"Up To Date": "",
		"Installed Version": "Unknown - Failed to retrieve information.", 
		"Latest Release Version": "Unknown - Failed to retrieve information.", 
		"Installed Size": "Unknown - Failed to retrieve information.", 
		"Latest Release Size": "Unknown - Failed to retrieve information.", 
		"Sources": "", 
		}
	var installed : bool = len(location.replace(" ", "")) > 0 and FileAccess.file_exists(location)
	app_info["Location Valid"] = str(installed).capitalize()
	var up_to_date : bool = false
	if installed:
		const platform_to_buffer_size : PackedInt32Array = [2, 4, 0]
		var buffer : PackedByteArray = FileAccess.open(location, FileAccess.READ).get_buffer(platform_to_buffer_size[UserManager.platform])
		if len(buffer) == platform_to_buffer_size[UserManager.platform]:
			match UserManager.platform:
				APIManager.platforms.WINDOWS:
					app_info["Executable"] = str((buffer[0] == 0x4d and buffer[1] == 0x5a) and location.get_extension() == "exe").capitalize()
				APIManager.platforms.LINUX:
					app_info["Executable"] = str(GeneralManager.mass_equal(buffer, [0x45, 0x4c, 0x46])).capitalize()
	print("here")
	var fetch_thread : Thread = Thread.new()
	fetch_thread.start(Callable(APIManager, &"fetch_info").bindv([open_app, APIManager.info_types.LATEST_VERSION]))
	while fetch_thread.is_alive():
		await get_tree().process_frame
	var latest_version_fetch : APIManager.response = fetch_thread.wait_to_finish()
	latest_version_fetch._get_details()
	if latest_version_fetch.success:
		app_info["Latest Release Version"] = latest_version_fetch.returned_str
		if UserManager.platform == APIManager.platforms.WINDOWS:
			app_info["Latest Release Version"] = GeneralManager.version_to_windows_version(app_info["Latest Release Version"])
	fetch_thread.start(Callable(APIManager, &"fetch_info").bindv([open_app, APIManager.info_types.EXECUTABLE_SIZE]))
	while fetch_thread.is_alive():
		await get_tree().process_frame
	var executable_size_fetch : APIManager.response = fetch_thread.wait_to_finish()
	if executable_size_fetch.success:
		app_info["Latest Release Size"] = String.humanize_size(int(executable_size_fetch.returned_str))
	if FileAccess.file_exists(location):
		match UserManager.platform:
			APIManager.platforms.WINDOWS:
				var out : Array[Variant]
				var cmd : String = '(Get-Item "' + location.replace("/", "\\") + '").VersionInfo.FileVersion'
				OS.execute("powershell.exe", ["-encodedcommand", Marshalls.raw_to_base64(cmd.to_utf16_buffer())], out, true)
				app_info["Installed Version"] = out[0].replace("\r", "").replace("\n", "").replace(" CLIXML", "").get_slice("<", 1)
				if app_info["Installed Version"].replace(" ", "") == "":
					app_info["Installed Version"] = "Unknown - Unknown error / exception happened."
			APIManager.platforms.LINUX:
				var out : Array[Variant] = []
				OS.execute("file", ["-c", location], out, true)
				print(out)
				print(out[-2])
				# I dont use linux so I cant test this so I have this here,
				# someone else can hopefully make this work, i think this is kinda right maybe
				app_info["Installed Version"] = "Unknown - Can not retrieve installed version on Linux platforms currently."
		app_info["Installed Size"] = String.humanize_size(FileAccess.open(location, FileAccess.READ).get_length())
	up_to_date = app_info["Latest Release Version"] == app_info["Installed Version"]
	app_info["Up To Date"] = str(up_to_date).capitalize()
	var categories : Array[APIManager.product_category]
	categories.assign(APIManager.product_to_product_categories[app])
	for i : int in range(0, len(categories)):
		app_info["Categories"] += APIManager.product_category.find_key(categories[i]).capitalize() + [", ", ""][int(i == (len(categories) - 1))]
	var api_availability : Array[bool]
	api_availability.assign(APIManager.product_to_api_availability[open_app])
	for i : int in range(0, len(api_availability)):
		if api_availability[i] == true:
			app_info["Sources"] += APIManager.api_to_api_name[i] + [", ", ""][int(i == api_availability.rfind(true))]
	for key : String in app_info:
		%AppContent/InfoGreaterContainer/InfoContainer/InfoLabel.text += "\n    " + key + ": " + app_info[key]
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/LaunchButton.set_meta("FileTargetState", int(installed) + int(app_info["Executable"].to_lower() == "true"))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/LaunchButton.text = [" Install ", " Repair ", " Launch "][%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/LaunchButton.get_meta("FileTargetState", 0)]
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/UpdateButton.visible = !up_to_date and installed
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/SourceButton.visible = len(location.replace(" ", "")) > 0 and (location.is_absolute_path())
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/InstallOptionsButton.visible = installed
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/OtherOptionsButton.visible = installed
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/PointButton.visible = !installed
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

func initiate_download(downloaded_file_name : String, product : APIManager.product, write_location : String = UserManager.settings[&"DefaultDownloadLocation"]) -> void:
	print("initiating download")
	%DownloadScreen/Panel.position = Vector2(555.0, 312.188)
	%DownloadScreen/Panel/Container/NerdInfo.visible = UserManager.settings[&"InfoForNerds"]
	GeneralManager.open_background_and_panel(true, %DownloadScreen, %DownloadScreen/Panel)
	await get_tree().process_frame
	if not DirAccess.dir_exists_absolute(write_location):
		_report_failure("Main Failure", "The destined write path in initaite_download was invalid", {"file_name": downloaded_file_name, "product": product, "write_location": write_location})
		return
	var resp : APIManager.response = await APIManager.download_executable(product)
	var file : FileAccess = FileAccess.open(write_location + "\\" + downloaded_file_name, FileAccess.WRITE)
	if not resp.success:
		print("i failed to download :(")
		resp._get_details()
		_report_failure("Main Failure", "A failure occured when initiating a download", {"file_name": downloaded_file_name, "product": product, "write_location": product, "failure": resp.failure, "details": resp.details})
		return
	%DownloadScreen/Panel/Container/Title.text = "File Writing In Progress..."
	await get_tree().process_frame
	%DownloadScreen/Panel/Container/ProgressBar.value = 0.0
	file.store_buffer(resp.returned_byt)
	%DownloadScreen/Panel/Container/ProgressBar.value = 0.5
	file.close()
	%DownloadScreen/Panel/Container/ProgressBar.value = 1.0
	await get_tree().process_frame
	GeneralManager.open_background_and_panel(false, %DownloadScreen, %DownloadScreen/Panel)
	return

func toggle_main_download_screen(state : bool) -> void:
	GeneralManager.open_background_and_panel(state, %DownloadScreen, %DownloadScreen/Panel)
	return

func update_download_visuals(target_name : String, version : String, platform : String, api : String, download_size : int, time_elapsed : float, progress : int, last_packet_size : int, host : String) -> void:
	%DownloadScreen/Panel/Container/Title.text = "Download In Progress" + "".lpad((int(Engine.get_frames_drawn() / 10.0) % 3) + 1, ".")
	var percentage : float = float(progress) / float(download_size)
	%DownloadScreen/Panel/Container/AppDetails/Name.text = target_name
	%DownloadScreen/Panel/Container/AppDetails/Version.text = "V" + version
	%DownloadScreen/Panel/Container/AppDetails/Platform.text = platform.capitalize() + " Build"
	%DownloadScreen/Panel/Container/DownloadDetails/API.text = "From: " + api
	%DownloadScreen/Panel/Container/Time.text = "Time Elapsed: " + str(time_elapsed).left(str(time_elapsed).find(".") + 3) + "s\nTime To Completion Estimate: " + str(int(maxf(time_elapsed, 0.1) / maxf(percentage, 0.1))) + "s"
	%DownloadScreen/Panel/Container/ProgressBar.value = percentage
	%DownloadScreen/Panel/Container/Size.text = String.humanize_size(progress) + "/" + String.humanize_size(download_size)
	%DownloadScreen/Panel/Container/NerdInfo/Row1/LastPacketSize.text = "Last Packet Size: " + String.humanize_size(last_packet_size)
	%DownloadScreen/Panel/Container/NerdInfo/Row1/Host.text = "Host: " + host
	%DownloadScreen/Panel/Container/NerdInfo/PacketUsage.text = "Packet Usage (Last Packet Size / DownloadMaximumPacketSize): " + str((last_packet_size / UserManager.settings[&"DownloadMaximumPacketSize"]) * 100) + "%"
	#%DownloadScreen/Panel.position = Vector2(555.0, 312.188)
	return

func open_mini_menu(title : String, menu_scene : PackedScene, args : Dictionary[StringName, Variant] = {}) -> void:
	$Camera/ScreenContainer/MiniMenu.title = title
	$Camera/ScreenContainer/MiniMenu.page = menu_scene
	for key : StringName in args.keys():
		$Camera/ScreenContainer/MiniMenu/Panel/Container/Body.get_child(-1).set(key, args[key])
	$Camera/ScreenContainer/MiniMenu.open = true
	return

func get_confirmation(text : String, buttons_text : PackedStringArray = ["No", "Yes"]) -> int:
	$Camera/ScreenContainer/ConfirmationDialog.text = text
	$Camera/ScreenContainer/ConfirmationDialog.buttons_text = buttons_text
	$Camera/ScreenContainer/ConfirmationDialog.open = true
	await $Camera/ScreenContainer/ConfirmationDialog.button_pressed
	return $Camera/ScreenContainer/ConfirmationDialog.pressed_button

func create_alert(title : String, text : String) -> void:
	$Camera/ScreenContainer/AlertContainer.add_child(alert_scene.instantiate())
	$Camera/ScreenContainer/AlertContainer.get_child(-1).fire(title, text)
	return

func _exit() -> void:
	_report_failure("Main Notification", "Exiting per user request", {})
	loading = true
	await get_tree().process_frame
	UserManager.save_data()
	if UserManager.settings[&"AlwaysWriteErrorLog"]:
		UserManager.write_error_log()
	get_tree().quit()
	return

func _report_failure(type : String, description : String, details : Dictionary[String, Variant], alert : bool = false) -> void:
	UserManager.append_to_error_log(type, description, details)
	if alert:
		create_alert(type, "A failure occured when fetching information;\nplease check / report your error log from the settings.")
	return
