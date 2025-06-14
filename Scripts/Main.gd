extends Control

##res://Scenes/ProductsList.tscn
const product_list : PackedScene = preload("res://Scenes/ProductsList.tscn")
##res://Scenes/CustomTextureButton.tscn
const custom_texture_button : PackedScene = preload("res://Scenes/CustomTextureButton.tscn")
##res://Scenes/InstallOptionsMiniMenu.tscn
const install_options_mini_menu : PackedScene = preload("res://Scenes/InstallOptionsMiniMenu.tscn")
##res://Scenes/OtherOptionsMiniMenu.tscn
const other_options_mini_menu : PackedScene = preload("res://Scenes/OtherOptionsMiniMenu.tscn")
##res://Scenes/SourceMiniMenu.tscn
const source_mini_menu : PackedScene = preload("res://Scenes/SourceMiniMenu.tscn")
##res://Scenes/Alert.tscn
const alert_scene : PackedScene = preload("res://Scenes/Alert.tscn")
##%DownloadIcon
@onready var download_icon : TextureButton = %DownloadIcon
##[member download_icon].material
@onready var download_icon_material : ShaderMaterial = download_icon.material
##[member download_icon].get_parent().get_child(2)
@onready var download_icon_separator : Panel = download_icon.get_parent().get_child(2)
##Sets if the loading screen is visible or not
@export var loading : bool = true:
	set(value):
		loading = value
		if loading:
			$Camera/ScreenContainer/LoadingScreen.modulate.a = 1
			$Camera/ScreenContainer/LoadingScreen/Icon.modulate.a = 1
			$Camera/ScreenContainer/LoadingScreen.visible = true
		else:
			create_tween().tween_property($Camera/ScreenContainer/LoadingScreen/Icon, "modulate:a", 0, 0.15).from(1)
			await create_tween().tween_property($Camera/ScreenContainer/LoadingScreen, "modulate:a", 0, 0.15).from(1).finished
			$Camera/ScreenContainer/LoadingScreen.visible = false
##Sets if the soft-loading screen is visible or not
@export var soft_loading : bool = false:
	set(value):
		soft_loading = value
		$Camera/ScreenContainer/SoftLoadingScreen.visible = value
##Sets if the download icon is visible if 'InfoForNerds' setting is also enabled
@export var downloading : bool = false:
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
##Sets if the tooltip is visible and maintains its position relative to the mouse while it is
@export var tooltip : bool = false:
	set(value):
		tooltip = value
		var tip : PanelContainer = $Camera/ScreenContainer/TooltipContainer/Tooltip
		tip.visible = tooltip
		while tooltip:
			tip.global_position = get_global_mouse_position() - Vector2(-10, -10)
			tip.global_position = GeneralManager.clamp_vec2(
				Vector2(tip.global_position.x, tip.global_position.y), 
				0, 1920 - int(tip.size.x), 
				0, 1080 - int(tip.size.y))
			await get_tree().process_frame
##Sets the tooltips text
@export var tooltip_txt : String = "Tooltip text.":
	set(value):
		tooltip_txt = value
		$Camera/ScreenContainer/TooltipContainer/Tooltip/MarginContainer/Text.text = tooltip_txt
		$Camera/ScreenContainer/TooltipContainer/Tooltip.size = Vector2.ZERO
##Sets if the tutorial screen is visible[br][br]Also see [member tutorial_page]
@export var tutorial : bool = false:
	set(value):
		tutorial = value
		if tutorial:
			tutorial_page = 0
		GeneralManager.open_background_and_panel(tutorial, $Camera/ScreenContainer/Tutorial, $Camera/ScreenContainer/Tutorial/Panel, 400, 312)
##Sets the current tutorial page[br][br]Also see [member tutorial]
@export var tutorial_page : int = 0:
	set(value):
		tutorial_page = clampi(value, 0, len(tutorial_text))
		$Camera/ScreenContainer/Tutorial/Panel/Container/Content.text = tutorial_text[tutorial_page]
		$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/Label.text = "Page " + str(tutorial_page + 1) + "/" + str(len(tutorial_text))
		$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/BackButton.disabled = tutorial_page == 0
		$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/BackButton.mouse_default_cursor_shape = [CURSOR_POINTING_HAND, CURSOR_FORBIDDEN][int(tutorial_page == 0)]
		$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/ForwardButton.disabled = tutorial_page == (len(tutorial_text) - 1)
		$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/ForwardButton.mouse_default_cursor_shape = [CURSOR_POINTING_HAND, CURSOR_FORBIDDEN][int(tutorial_page == (len(tutorial_text) - 1))]
##The [Mutex] to set the [member downloading] variable
var downloading_mutex : Mutex = Mutex.new()
##The app currently open inside the app body
var open_app : APIManager.product = APIManager.product.UNKNOWN
##The product shortcuts from [b]UserManager[/b].settings[lb]&"ProductShortcuts"[rb] as their [b]APIManager[/b] values
var product_shortcuts : Array[APIManager.product]:
	get:
		var prod_shorts : Array[APIManager.product]
		prod_shorts.assign(UserManager.settings[&"ProductShortcuts"].map(
			func(item : String) -> APIManager.product:
				return APIManager.product.get(item, APIManager.product.UNKNOWN)))
		return prod_shorts
##All the previously loaded temporary assets, the following is a table for each stored file type and its dictionary:[br]-Image: {"buffer": [], "size": Vector2()}
var temporary_loaded_assets : Dictionary[String, Dictionary]
##The settings page data
const settings_page_data : Dictionary[StringName, PackedScene] = {
	&"General Settings": preload("res://Scenes/SettingsGeneralPage.tscn"), 
	&"Display Settings": preload("res://Scenes/SettingsDisplayPage.tscn"), 
	&"API Keys": preload("res://Scenes/SettingsApiPage.tscn"), 
	&"Theme Settings": preload("res://Scenes/SettingsThemePage.tscn"), 
	&"Updates": preload("res://Scenes/SettingsUpdatesPage.tscn"), 
	&"Programme": preload("res://Scenes/SettingsProgrammePage.tscn"), 
	&"Details": preload("res://Scenes/SettingsDetailsPage.tscn"), 
	}
const tutorial_text : PackedStringArray = [
	"[center]\n[img]res://Assets/NSL_Icon.png[/img]\n\nWelcome to the NZG Software Launcher!\n\nThis is a short tutorial to help you get started using this launcher,\nif you wish to skip this you can close it using the button in the top right of this panel,\nthis can always be reopened in the General page in Settings\n\nYou can navigate using the buttons below.[/center]", 
	"[center]\nIn the background is the Products page, where all the NZG products are\nlisted and are available to download and manage.\n\nUpon opening a products page a shortcut to reopen its page will appear in the sidebar on the left in the order of when they were last opened.\n\nThese shortcuts are preserved when closing the app, and can be activated using their corresponding number or function key\n(The first one can be opened with 1 / F1, second with 2 / F2, etc.)[/center]", 
	"[center]\nOn an apps page you can view all of its details and compare it to your installed version, including it's description, size and version.\n\nThis is also where you can install the given app, or if you are already have the related product installed you can point the launcher to the app and then use the launcher with that installed version.\n\nIf your app version is found to be out of date then you will be given the option to update to the latest version, though this is not required and you can still launch the app if it is out of date.\n\n[color=red][font_size=22]NOTE: While launching and managing your own installation does not require a network connection, to compare against the latest version or download the app a network connection is required[/font_size][/color][/center]", 
	"[center]\n[img]res://Assets/TutorialImages/Image1.png[/img]\n\nTo modify the app you can head to the Settings using the cogwheel in the top right, this can be used to change all relevant settings including your Theme / Colour Settings, API Keys and more.\n\nInside the 'Updates' section of the Settings page is also where you can update to the latest launcher version if it is available, just like with apps you are not required to update to the latest version though it is recommended for bug fixes, improvements and possibly new products being available.[/center]", 
	"[center]\nAdditional information:\n\nTo return to the Products page you can use the button in the bottom left with the shopping icon.\n\nTo go to some of the NZG socials you can use the globe icon in the top left below the NZG icon.\n\nFor more technical details about the app you can read the 'Details' page in the Settings.\n\nIf your launcher version is found to be out of date upon opening the launcher you will receive an alert and a notification below the Socials button in the top left, again it is not required to update but it is recommended.[/center]", 
	"[center]\n[img]res://Assets/NSL_Icon.png[/img]\n\nYou are now ready to use the NZG Software Launcher!\n\nTo get started you can now close this tutorial and browse the list of products, and if you ever need to re-read the tutorial you can reopen it inside the General page of the Settings.[/center]", 
	]
const reactive_button_code : String = "extends TextureButton\nvar spd : float = 1.0\nfunc _init() -> void:\n\twhile true:\n\t\tif self.button_pressed:\n\t\t\tspd = clampf(spd - 0.2, 0.75, 1.0)\n\t\telif self.is_hovered():\n\t\t\tspd = clampf(spd - 0.1, 0.85, 1.0)\n\t\telse:\n\t\t\tspd = clampf(spd + 0.05, 0.0, 1.0)\n\t\tself.material.set(&'shader_parameter/scale', spd)\n\t\tawait get_tree().process_frame\n\treturn"

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
	%DownloadIcon.mouse_entered.connect(
		func() -> void:
			_lock_download_mutexes()
			tooltip_txt = "Progress: " + str(int(%DownloadIcon.material.progress * 100)) + "%\nHost: " + APIManager.request_host + "\nLast Packet Size: " + String.humanize_size(APIManager.last_packet_size)
			_unlock_download_mutexes()
			tooltip = true
			return)
	%DownloadIcon.mouse_exited.connect(func() -> void: tooltip = false; return)
	%"DownloadIcon/../Void1".visible = false
	%SettingsButton.texture_normal = IconLoader.icons[&"Options"]
	%SettingsButton.pressed.connect(func() -> void: $Camera/ScreenContainer/PopupPage.open = true; return)
	%SettingsButton.set_script(GeneralManager.create_gdscript("extends TextureButton\nvar spd : float = 0.0\nfunc _init() -> void:\n\twhile true:\n\t\tawait get_tree().process_frame\n\t\tspd += (-0.001 + (0.01 * float(int(self.is_hovered()))))\n\t\tspd = clampf(spd, 0.0, 0.02)\n\t\tself.material.set('shader_parameter/rot', fposmod(self.material.get('shader_parameter/rot') + spd, 1.0))\n\treturn\n"))
	%SettingsButton.mouse_entered.connect(func() -> void: tooltip_txt = "Settings"; tooltip = true; return)
	%SettingsButton.mouse_exited.connect(func() -> void: tooltip = false; return)
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
	%MainContainer/SidePanel/Container/SocialsButton.mouse_entered.connect(func() -> void: tooltip_txt = "Open Socials List"; tooltip = true; return)
	%MainContainer/SidePanel/Container/SocialsButton.mouse_exited.connect(func() -> void: tooltip = false; return)
	for row : HBoxContainer in %SocialsPopup/Container.get_children().filter(func(item : Node) -> bool: return item.get_class() == "HBoxContainer"):
		row.get_child(3).mouse_entered.connect(func() -> void: tooltip_txt = row.get_child(3).uri; tooltip = true; return)
		row.get_child(3).mouse_exited.connect(func() -> void: tooltip = false; return)
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
	%MainContainer/SidePanel/Container/AlertButton.mouse_entered.connect(func() -> void: tooltip_txt = "Alert; Click for more details"; tooltip = true; return)
	%MainContainer/SidePanel/Container/AlertButton.mouse_exited.connect(func() -> void: tooltip = false; return)
	%AlertPopup/Container/Container/ActionButton.pressed.connect(func() -> void: $Camera/ScreenContainer/PopupPage.set_page(settings_page_data.keys().find(&"Updates")); $Camera/ScreenContainer/PopupPage.open = true; %MainContainer/SidePanel/Container/AlertButton.button_pressed = false; return)
	%MainContainer/SidePanel/Container/ProductsPageButton.texture_normal = IconLoader.load_svg_to_img("res://Assets/Icons/Products.svg", 3.0)
	%MainContainer/SidePanel/Container/ProductsPageButton.pressed.connect(func() -> void: %AppBody.visible = false; %ProductsBody.visible = true; %Header/Container/PageTitle.text = "  Products"; return)
	%MainContainer/SidePanel/Container/ProductsPageButton.mouse_entered.connect(func() -> void: tooltip_txt = "Open Products Page"; tooltip = true; return)
	%MainContainer/SidePanel/Container/ProductsPageButton.mouse_exited.connect(func() -> void: tooltip = false; return)
	%MainContainer/SidePanel/Container/ProductsPageButton.set_script(GeneralManager.create_gdscript(reactive_button_code))
	$Camera/ScreenContainer/PopupPage.data.assign(settings_page_data)
	$Camera/ScreenContainer/PopupPage.data = $Camera/ScreenContainer/PopupPage.data
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/LaunchButton.pressed.connect(Callable(self, &"app_button_pressed").bind(0))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/UpdateButton.pressed.connect(Callable(self, &"app_button_pressed").bind(1))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/SourceButton.pressed.connect(Callable(self, &"app_button_pressed").bind(2))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/InstallOptionsButton.pressed.connect(Callable(self, &"app_button_pressed").bind(3))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/OtherOptionsButton.pressed.connect(Callable(self, &"app_button_pressed").bind(4))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/PointButton.pressed.connect(Callable(self, &"app_button_pressed").bind(5))
	%AppContent/ActionButtonsGreaterContainer/ActionButtonsContainer/WebSourceButton.pressed.connect(Callable(self, &"app_button_pressed").bind(6))
	%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.meta_hover_started.connect(
		func(txt : String) -> void:
			if txt.begins_with("!"):
				tooltip_txt = txt.right(-1).get_file()
			else:
				tooltip_txt = txt
			tooltip = true
			return)
	%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.meta_hover_ended.connect(func(_txt : String) -> void: tooltip = false; return)
	%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.meta_clicked.connect(
		func(txt : String) -> void:
			if txt.begins_with("!") and Marshalls.utf8_to_base64(txt.right(-1)) in temporary_loaded_assets.keys():
				open_image_preview(txt.right(-1))
			else:
				OS.shell_open(txt)
			return)
	$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/BackButton.pressed.connect(func() -> void: tutorial_page -= 1; return)
	$Camera/ScreenContainer/Tutorial/Panel/Container/Navigation/ForwardButton.pressed.connect(func() -> void: tutorial_page += 1; return)
	$Camera/ScreenContainer/Tutorial/Panel/Container/TitleContainer/CloseButton.texture_normal = IconLoader.icons[&"Close"]
	$Camera/ScreenContainer/Tutorial/Panel/Container/TitleContainer/CloseButton.pressed.connect(func() -> void: tutorial = false; return)
	populate_products_page()
	populate_shortcut_list()
	%ProductsBody/ScrollContainer.get_v_scroll_bar().set(&"mouse_default_cursor_shape", DisplayServer.CURSOR_VSIZE)
	$Camera/ScreenContainer/ConfirmationDialog.visible = false
	%DownloadScreen.visible = false
	$Camera/ScreenContainer/ImagePreviewScreen.visible = false
	%AppBody.visible = false
	%ProductsBody.visible = true
	$Camera/ScreenContainer/MiniMenu.open = false
	soft_loading = false
	tooltip = false
	downloading = false
	$Camera/ScreenContainer/PopupPage.open = false
	%SocialsPopup.visible = false
	%AlertPopup.visible = false
	UpdateManager.main = self
	if not OS.has_feature("editor"):
		UpdateManager.get_latest_version_info()
	%MainContainer/SidePanel/Container/AlertButton.visible = UpdateManager.retrieved_latest_version_info and UpdateManager.latest_version != UpdateManager.current_version
	tutorial = UserManager.new_user
	@warning_ignore_restore("static_called_on_instance")
	#
	loading = false
	await get_tree().create_timer(0.2).timeout
	if %MainContainer/SidePanel/Container/AlertButton.visible:
		create_alert("Update Available", "Your app version " + UpdateManager.current_version + " does not match\nthe latest version of " + UpdateManager.latest_version + ".\nYou can download the update in the\nsettings menu under the 'Updates' page.")
	elif not UpdateManager.retrieved_latest_version_info:
		create_alert("Update Error", "Failed to check for the latest app version\nyou can check again by restarting the app or in the\nsettings in the 'Updates' page.")
	return

func _input(event: InputEvent) -> void:
	if event.get_class() in ["InputEventMouseMotion"]:
		return
	if %AppBody.visible and (Input.is_action_just_pressed(&"ScrollUp") or Input.is_action_just_pressed(&"ScrollDown")):
		if not (true in [
				$Camera/ScreenContainer/LoadingScreen.visible, 
				$Camera/ScreenContainer/SoftLoadingScreen.visible, 
				%DownloadScreen.visible, 
				$Camera/ScreenContainer/ConfirmationDialog.visible, 
				$Camera/ScreenContainer/PopupPage.visible, 
				$Camera/ScreenContainer/MiniMenu.visible, 
				$Camera/ScreenContainer/ImagePreviewScreen.visible, 
				]):
			%AppBody/Container/ScrollBar.value += float(0.025 * int(Input.get_axis(&"ScrollDown", &"ScrollUp"))) * -1
			tooltip = false
			return
	if $Camera/ScreenContainer/ImagePreviewScreen.visible and (Input.is_action_just_pressed(&"ScrollUp") or Input.is_action_just_pressed(&"ScrollDown")):
		var sizes : Array[Vector2] = [Vector2(1440.0, 810.0), Vector2(1920.0, 1080.0)]
		var positions : Array[Vector2] = [Vector2(240.0, 135.0), Vector2.ZERO]
		var state : bool = Input.is_action_just_pressed(&"ScrollUp")
		if $Camera/ScreenContainer/ImagePreviewScreen/Image.size == sizes[int(state)]:
			return
		if not $Camera/ScreenContainer/ImagePreviewScreen/Image.size in sizes:
			return
		create_tween().tween_property($Camera/ScreenContainer/ImagePreviewScreen/Image, "size", sizes[int(state)], 0.15).from(sizes[int(!state)]).set_ease(Tween.EASE_IN)
		create_tween().tween_property($Camera/ScreenContainer/ImagePreviewScreen/Image, "position", positions[int(state)], 0.15).from(positions[int(!state)]).set_ease(Tween.EASE_IN)
		return
	if not (Input.is_action_just_pressed(&"ScrollUp") or Input.is_action_just_pressed(&"ScrollDown")) and Input.is_anything_pressed() and $Camera/ScreenContainer/ImagePreviewScreen.visible:
		await GeneralManager.open_background_and_panel(false, $Camera/ScreenContainer/ImagePreviewScreen, $Camera/ScreenContainer/ImagePreviewScreen/Image)
		await get_tree().process_frame
		$Camera/ScreenContainer/ImagePreviewScreen/Image.custom_minimum_size = Vector2(1440.0, 810.0)
		$Camera/ScreenContainer/ImagePreviewScreen/Image.size = Vector2.ZERO
		$Camera/ScreenContainer/ImagePreviewScreen/Image.position = Vector2(240.0, 135.0)
		return
	if not (true in [
				$Camera/ScreenContainer/LoadingScreen.visible, 
				$Camera/ScreenContainer/SoftLoadingScreen.visible, 
				%DownloadScreen.visible, 
				$Camera/ScreenContainer/ConfirmationDialog.visible, 
				$Camera/ScreenContainer/PopupPage.visible, 
				$Camera/ScreenContainer/MiniMenu.visible, 
				$Camera/ScreenContainer/ImagePreviewScreen.visible, 
				]):
		var prod_shorts : Array[APIManager.product] = product_shortcuts
		for i : int in range(0, 10):
			if i > len(prod_shorts):
				break
			if event.is_action_pressed(StringName("AppShortcut" + str(i+1)), false, true):
				open_app_page(prod_shorts[i])
				break
	return

##Parses and acts upon the arguments given by the CLI
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
		DirAccess.remove_absolute(OS.get_executable_path().get_base_dir() + "/" + args["kill_old_nsl_process"])
		await get_tree().create_timer(0.1).timeout
		DirAccess.rename_absolute(OS.get_executable_path(), args["kill_old_nsl_process"])
	return

##Called when an app body button is pressed and does the relevant logic
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
					UserManager.settings[&"ProductToInstallLocation"][APIManager.product.find_key(open_app)] = %PickInstallLocationDialog.current_path + "/" + file_name
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

##Opens the page for the given [param app]
func open_app_page(app : APIManager.product) -> void:
	soft_loading = true
	await get_tree().process_frame
	%AppBody.visible = false
	%AppBody/Container/ScrollBar.value = 0.0
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
	var fetch_thread : Thread = Thread.new()
	fetch_thread.start(Callable(APIManager, &"fetch_info").bindv([open_app, APIManager.info_types.DESCRIPTION]))
	while fetch_thread.is_alive():
		await get_tree().process_frame
	#breakpoint
	var description_response : APIManager.response = fetch_thread.wait_to_finish()
	%AppContent/InfoGreaterContainer/InfoContainer/Description.text = "[Description Not Found]"
	if description_response.success:
		%AppContent/InfoGreaterContainer/InfoContainer/Description.text = description_response.returned_str
	%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.text = ""
	if APIManager.product_to_api_availability[open_app][APIManager.api.GITHUB] == true:
		%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.text = "[ReadMe Not Found]"
		fetch_thread.start(Callable(APIManager, &"fetch_info").bindv([open_app, APIManager.info_types.READ_ME]))
		while fetch_thread.is_alive():
			await get_tree().process_frame
		#breakpoint
		var read_me_response : APIManager.response = fetch_thread.wait_to_finish()
		if read_me_response.success:
			%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.text = ""
			var assets_to_get : Dictionary[String, PackedStringArray] = GeneralManager.get_inteligent_readme_asset_paths(GeneralManager.get_readme_assets(read_me_response.returned_str))
			print(assets_to_get)
			var lines : PackedStringArray = read_me_response.returned_str.split("\n")
			var line : String
			var img_path : String
			var old_name : String
			var img_regex : RegEx = RegEx.new()
			var hyperlink_regex : RegEx = RegEx.new()
			img_regex.compile("[^()]*", true)
			hyperlink_regex.compile("\\[.*\\]\\(.*\\)", true)
			for i : int in range(0, len(lines)):
				line = lines[i]
				#breakpoint
				if line.begins_with("#") and line.ends_with("#"):
					line = "[b][font_size=23]" + line.replace("#", "") + "[/font_size][/b]\n" + "".lpad(len(line.replace("#", "")), "━")
				elif line.begins_with(">"):
					line = line.right(-1)
					while line.left(1) == " ": line = line.right(-1)
					if line.begins_with("[!") and line.ends_with("]"):
						line = "[b][u][color=#006aff]" + line.right(-2).left(-1) + "[/color][/u][/b]"
					line = "[font_size=25][color=#006aff]│[/color]\t" + line + "[/font_size]"
				elif line.begins_with("![") and "](" in line and line.ends_with(")"):
					img_path = line.right((len(img_regex.search(line).strings[0]) + 1) * -1).left(-1)
					old_name = img_path
					#print(img_path)
					if not img_path.get_base_dir() in assets_to_get.keys():
						continue
					if not Marshalls.utf8_to_base64(img_path) in temporary_loaded_assets.keys():
						print("fetching asset")
						fetch_thread.start(Callable(APIManager, &"fetch_github_asset").bindv([open_app, [img_path.get_base_dir(), img_path][int(len(assets_to_get[img_path.get_base_dir()]) == 1)]]))
						while fetch_thread.is_alive():
							await get_tree().process_frame
						var fetch : APIManager.response = fetch_thread.wait_to_finish()
						if fetch.success:
							if len(assets_to_get[img_path.get_base_dir()]) == 1:
								#print("it was one item")
								var img : Image = Image.new()
								img.load_png_from_buffer(fetch.returned_byt)
								temporary_loaded_assets[Marshalls.utf8_to_base64(img_path)] = {"buffer": fetch.returned_byt, "size": Vector2(img.get_size())}
							else:
								var json : Array[Dictionary]
								json.assign(JSON.parse_string(fetch.returned_str))
								for asset : Dictionary[String, Variant] in json:
									#print(asset, "\n")
									if asset["name"] in assets_to_get[img_path.get_base_dir()]:
										fetch_thread.start(Callable(APIManager, &"_request_url").bindv([
											asset["download_url"], 
											["X-GitHub-Api-Version:2022-11-28"], 
											'{"owner":"natzombiegames","repo":"' + APIManager.github_product_to_github_name[open_app].to_snake_case() + '"}', 
											"", 
											APIManager.return_types.BYT
											]))
										while fetch_thread.is_alive():
											await get_tree().process_frame
										var resp : APIManager.response = fetch_thread.wait_to_finish()
										if resp.success:
											var img : Image = Image.new()
											img.load_png_from_buffer(resp.returned_byt)
											temporary_loaded_assets[Marshalls.utf8_to_base64(img_path.get_base_dir() + "/" + asset["name"])] = {"buffer": resp.returned_byt, "size": Vector2(img.get_size())}
					img_path = Marshalls.utf8_to_base64(img_path)
					if img_path in temporary_loaded_assets.keys():
						#print("it exists")
						var img_size : Vector2 = GeneralManager.clamp_vec2(temporary_loaded_assets[img_path]["size"], 
							100, 1280, 100, 720)
						var img : Image = Image.create_empty(int(img_size.x), int(img_size.y), false, Image.FORMAT_RGBA8)
						img.load_png_from_buffer(temporary_loaded_assets[img_path]["buffer"])
						%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.add_image(
							ImageTexture.create_from_image(img), 
							img_size.x, img_size.y)
						line = "\n[url=!" + old_name + "][b](Open Image)[/b][/url]"
					else:
						print("no find '" + img_path + "' :(")
						line = "[Failed to retrieve image]"
				else:
					if line.replace(" ", "").begins_with("-"):
						var space : String = "".lpad(len(line.left(line.find("-"))) * 2, " ")
						line = space + ["•", "◦"][int(len(space) > 0)] + line.right(len(line) - line.find("-") - 1)
					if not (line.begins_with("!")) and hyperlink_regex.search(line) != null:
						var halves : PackedStringArray
						for hyperlink : String in hyperlink_regex.search(line).strings:
							halves = hyperlink.split("](", false, 2)
							line = line.replace(hyperlink, "[url=" + halves[1].left(-1) + "][u]" + halves[0].right(-1) + "[/u][/url]")
				%AppContent/InfoGreaterContainer/InfoContainer/ReadMe.append_text(line + "\n")
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
		if len(buffer) >= platform_to_buffer_size[UserManager.platform]:
			match UserManager.platform:
				APIManager.platforms.WINDOWS:
					app_info["Executable"] = str((buffer[0] == 0x4d and buffer[1] == 0x5a) and location.get_extension() == "exe").capitalize()
				APIManager.platforms.LINUX:
					app_info["Executable"] = str(GeneralManager.mass_equal(buffer, [0x45, 0x4c, 0x46])).capitalize()
	fetch_thread.start(Callable(APIManager, &"fetch_batch").bindv([open_app, APIManager.batch_types.GENERAL_INFO]))
	while fetch_thread.is_alive():
		await get_tree().process_frame
	var batch_fetch : Array[APIManager.response] = fetch_thread.wait_to_finish()
	#breakpoint
	if batch_fetch[0].success:
		app_info["Latest Release Version"] = batch_fetch[0].returned_str
		if UserManager.platform == APIManager.platforms.WINDOWS:
			app_info["Latest Release Version"] = GeneralManager.version_to_windows_version(app_info["Latest Release Version"])
		app_info["Latest Release Size"] = String.humanize_size(int(batch_fetch[2].returned_str))
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
				app_info["Installed Version"] = "Unknown - Can not currently retrieve installed version on Linux platforms."
		app_info["Installed Size"] = String.humanize_size(FileAccess.open(location, FileAccess.READ).get_length())
	up_to_date = app_info["Latest Release Version"] == app_info["Installed Version"] and app_info["Latest Release Version"] != "Unknown - Failed to retrieve information."
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

##Populates the shortcuts on the sidebar
func populate_shortcut_list() -> void:
	var prod_shorts : Array[APIManager.product] = product_shortcuts
	prod_shorts.reverse()
	while %ShortcutList.get_child_count() < len(prod_shorts):
		%ShortcutList.add_child(custom_texture_button.instantiate())
		%ShortcutList.get_child(-1).get_child(0).material = preload("res://Assets/Materials/ShrinkMaterial.tres").duplicate()
		%ShortcutList.get_child(-1).get_child(0).set_script(GeneralManager.create_gdscript(reactive_button_code))
	for child : Control in %ShortcutList.get_children(): child.visible = false
	for i : int in range(0, len(prod_shorts)):
		%ShortcutList.get_child(i).button.texture_normal = IconLoader.product_icons[prod_shorts[i]]
		%ShortcutList.get_child(i).pressed_callable = Callable(self, &"open_app_page").bind(prod_shorts[i])
		GeneralManager.disconnect_connections(%ShortcutList.get_child(i).get_child(0).mouse_entered)
		GeneralManager.disconnect_connections(%ShortcutList.get_child(i).get_child(0).mouse_exited)
		%ShortcutList.get_child(i).get_child(0).mouse_entered.connect(func() -> void: tooltip_txt = "Open " + APIManager.product_to_name[prod_shorts[i]] + " Page"; tooltip = true; return)
		%ShortcutList.get_child(i).get_child(0).mouse_exited.connect(func() -> void: tooltip = false; return)
		%ShortcutList.get_child(i).visible = true
	await get_tree().process_frame
	for child : Control in %ShortcutList.get_children(): child.custom_minimum_size.y = child.size.x
	return

##Populates the products page
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

##Initiates a download for the given [param product] and if all succedes then writes the resulting binary to the [param downloaded_file_name] in the [param write_location]
func initiate_download(downloaded_file_name : String, product : APIManager.product, write_location : String = UserManager.settings[&"DefaultDownloadLocation"]) -> void:
	print("initiating download")
	%DownloadScreen/Panel.position = Vector2(555.0, 312.188)
	%DownloadScreen/Panel/Container/NerdInfo.visible = UserManager.settings[&"InfoForNerds"]
	GeneralManager.open_background_and_panel(true, %DownloadScreen, %DownloadScreen/Panel)
	await get_tree().process_frame
	%DownloadScreen/Panel.position = Vector2(555.0, 312.188)
	if not DirAccess.dir_exists_absolute(write_location):
		_report_failure("Main Failure", "The destined write path in initaite_download was invalid", {"file_name": downloaded_file_name, "product": product, "write_location": write_location})
		return
	var resp : APIManager.response = await APIManager.download_executable(product)
	var file : FileAccess = FileAccess.open(write_location + "/" + downloaded_file_name, FileAccess.WRITE)
	if not resp.success:
		print("i failed to download :(")
		resp._get_details()
		_report_failure("Main Failure", "A failure occured when initiating a download", {"file_name": downloaded_file_name, "product": product, "write_location": product, "failure": resp.failure, "details": resp.details})
		create_alert("Download Error", "An error occured when attempting to download,\nplease try again and if this issue persists check the\nError Log in the Programme section in Settings.")
		GeneralManager.open_background_and_panel(false, %DownloadScreen, %DownloadScreen/Panel)
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

##Toggles the download screen to the given [param state]
func toggle_main_download_screen(state : bool) -> void:
	GeneralManager.open_background_and_panel(state, %DownloadScreen, %DownloadScreen/Panel)
	return

##Updates the download screen's visuals using the given paramaters
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
	%DownloadScreen/Panel/Container/NerdInfo/PacketUsage.text = "Packet Usage (Last Packet Size / DownloadMaximumPacketSize): " + str(int((UserManager.settings[&"DownloadMaximumPacketSize"] / last_packet_size) * 100)) + "%"
	%DownloadScreen/Panel.position = Vector2(555.0, 312.188)
	return

##Opens the given [param menu_scene] with the given [param title] and [param args]
func open_mini_menu(title : String, menu_scene : PackedScene, args : Dictionary[StringName, Variant] = {}) -> void:
	$Camera/ScreenContainer/MiniMenu.title = title
	$Camera/ScreenContainer/MiniMenu.page = menu_scene
	for key : StringName in args.keys():
		$Camera/ScreenContainer/MiniMenu/Panel/Container/Body.get_child(-1).set(key, args[key])
	$Camera/ScreenContainer/MiniMenu.open = true
	return

##Opens the image preview using the [member temporary_loaded_assets] of the given [param loaded_asset_name].
func open_image_preview(loaded_asset_name : String) -> void:
	var texture : Image = Image.new()
	texture.load_png_from_buffer(temporary_loaded_assets[Marshalls.utf8_to_base64(loaded_asset_name)]["buffer"])
	$Camera/ScreenContainer/ImagePreviewScreen/Image.texture = ImageTexture.create_from_image(texture)
	GeneralManager.open_background_and_panel(true, $Camera/ScreenContainer/ImagePreviewScreen, $Camera/ScreenContainer/ImagePreviewScreen/Image)
	return

##Opens a confirmation popup with the given [param text] and [param buttons_text] and returns the button pressed (0-Indexed)
func get_confirmation(text : String, buttons_text : PackedStringArray = ["No", "Yes"]) -> int:
	$Camera/ScreenContainer/ConfirmationDialog.text = text
	$Camera/ScreenContainer/ConfirmationDialog.buttons_text = buttons_text
	$Camera/ScreenContainer/ConfirmationDialog.open = true
	await $Camera/ScreenContainer/ConfirmationDialog.button_pressed
	return $Camera/ScreenContainer/ConfirmationDialog.pressed_button

##Creates and fires an alert with the given [param title] and [param text]
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
	%MainContainer/SidePanel/Container/AlertButton.queue_free()
	await get_tree().process_frame
	get_tree().quit()
	return

##Appends to the [b]UserManager[/b]'s error log using 'UserManager.append_to_error_log()' with the given [param type], [param description] and [param details].[br][br]And if [param alert] is enabled then an alert will be fired using [method create_alert]
func _report_failure(type : String, description : String, details : Dictionary[String, Variant], alert : bool = false) -> void:
	UserManager.append_to_error_log(type, description, details)
	if alert:
		create_alert(type, "A failure occured when fetching information;\nplease check / report your error log from the settings.")
	return

##Locks all the [APIManager]'s mutexes
func _lock_download_mutexes() -> void:
	for mtx : APIManager.mutex_type in APIManager.mutex_type.values():
		APIManager.mutexes[mtx].lock()
	return

##Unlocks all the [APIManager]'s mutexes
func _unlock_download_mutexes() -> void:
	for mtx : APIManager.mutex_type in APIManager.mutex_type.values():
		APIManager.mutexes[mtx].unlock()
	return
