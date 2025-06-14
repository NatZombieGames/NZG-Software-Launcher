extends Node
##General manager for smaller utility functions

##For the given [param obj]; disconnects all signal connections by using [method disconnect_connections] on each [Signal] from [method Object.get_signal_list]
func disconnect_all_signals(obj : Object) -> void:
	for sig : Dictionary[String, Variant] in obj.get_signal_list():
		disconnect_connections(obj.get(StringName(sig["name"])))
	return

##Disconnects each connection for the given [param sig]
func disconnect_connections(sig : Signal) -> void:
	for connection : Dictionary in sig.get_connections():
		sig.disconnect(connection["callable"])
	return

##Returns [code]true[/code] if the two given [Array]s are equal, and [code]false[/code] otherwise
func mass_equal(dataset_1 : Array[Variant], dataset_2 : Array[Variant]) -> bool:
	for i : int in range(0, min(len(dataset_1), len(dataset_2))):
		if not dataset_1[i] == dataset_2[i]:
			return false
	return true

##Returns [code]true[/code] if every item in the given [param arr] is equal to the given [param value], and [code]false[/code] otherwise
func arr_equal(arr : Array[Variant], value : Variant) -> bool:
	for i : int in arr:
		if not arr[i] == value:
			return false
	return true

##Converts a given version to a ""windows"" (Major.Minor.Patch.Build) compatible version[br][codeblock]
##version_to_windows_version("1.5.3")     # 1.5.3.0
##version_to_windows_version("2.3.7.5")   # 2.3.7.5
##version_to_windows_version("1.0")       # 1.0.0.0
##version_to_windows_version("25")        # 25.0.0.0
##version_to_windows_version("5.3.8.5.1") # 5.3.8.5
##[/codeblock]
func version_to_windows_version(ver : String) -> String:
	var parts : PackedStringArray = []
	var split : PackedStringArray
	var res : String = ""
	parts.resize(4)
	parts.fill("0")
	split = ver.split(".", false)
	for i : int in range(0, mini(len(split), 4)):
		parts[i] = split[i]
	for num : String in parts:
		res += str(int(num)) + "."
	return res.left(-1)

##Animates the opening (or closing, based on [param state]) of the given [param background] and [param panel]
func open_background_and_panel(state : bool, background : ColorRect, panel : Control, start_y : int = 135, end_y : int = 170) -> void:
	background.visible = true
	var values : Array[Vector2i] = [Vector2i(1, 0), Vector2i(end_y, start_y)]
	create_tween().tween_property(background, "modulate:a", values[0][int(!state)], 0.15).from(values[0][int(state)])
	create_tween().tween_property(panel, "modulate:a", values[0][int(!state)], 0.15).from(values[0][int(state)])
	await create_tween().tween_property(panel, "position:y", values[1][int(!state)], 0.15).from(values[1][int(state)]).finished
	if not state:
		background.visible = false
	return

##Animates the opening (or closing, based on [param state]) of the given [param panel] and [param container]
func open_panel_and_container(state : bool, panel : PanelContainer, container : Container) -> void:
	if state:
		container.modulate.a = 0
		container.visible = true
		panel.visible = true
		await create_tween().tween_property(panel.material, "shader_parameter/progress", 1.0, 0.15).from(0.0).finished
		create_tween().tween_property(container, "modulate:a", 1.0, 0.15).from(0.0)
	else:
		await create_tween().tween_property(container, "modulate:a", 0.0, 0.15).from(1.0).finished
		await create_tween().tween_property(panel.material, "shader_parameter/progress", 0.0, 0.15).from(1.0).finished
		panel.visible = false
	return

##Creates a new [GDScript] object, sets the [member GDScript.source_code] to the given [param code], reloads the script with [Script.reload] before returning the script
func create_gdscript(code : String) -> GDScript:
	var script : GDScript = GDScript.new()
	script.source_code = code
	script.reload()
	return script

##Clamps a [Vector2]'s X and Y within the given ranges[br]Equal to:[br][codeblock]vector = Vector2(clampf(vector.x, minx, maxx), clampf(vector.y, miny, maxy)[/codeblock]
func clamp_vec2(vec : Vector2, minx : float, maxx : float, miny : float, maxy : float) -> Vector2:
	return Vector2(clampf(vec.x, minx, maxx), clampf(vec.y, miny, maxy))

##Returns a [String] of all the given [param arr]'s contents with the optional [param intermediary_string] inbetween each item
func arr_to_str(arr : Array[Variant], intermediary_string : String = "") -> String:
	var txt : String = ""
	for item : Variant in arr: txt += str(item) + [intermediary_string, ""][int(arr.rfind(item) == (len(arr) - 1))]
	return txt

##For the given [param readme], returns all the assets needed for image displays (Example [code]![Icon](Assets/Icon.png)[/code] would return [code]["Assets/Icon.png"][/code])[br][br]Also see [method get_inteligent_readme_asset_paths]
func get_readme_assets(readme : String) -> PackedStringArray:
	var assets : PackedStringArray
	var regex : RegEx = RegEx.new()
	var lines : PackedStringArray = readme.split("\n")
	var line : String
	regex.compile("[^()]*", true)
	for i : int in range(0, len(lines)):
		line = lines[i]
		if line.begins_with("![") and "](" in line and line.ends_with(")"):
			assets.append(line.right((len(regex.search(line).strings[0]) + 1) * -1).left(-1))
	return assets

##For the given [param assets] returns a [Dictionary] which has the path as a key and each asset from that path in a [PackedStringArray] as the value[br][br]Also see [method get_readme_assets]
func get_inteligent_readme_asset_paths(assets : PackedStringArray) -> Dictionary[String, PackedStringArray]:
	var dict : Dictionary[String, PackedStringArray] = {}
	var dir : String
	for asset : String in assets:
		if "/" in asset:
			dir = asset.get_base_dir()
			if dir in dict.keys():
				dict[dir].append(asset.get_file())
			else:
				dict[dir] = PackedStringArray([asset.get_file()])
	return dict
