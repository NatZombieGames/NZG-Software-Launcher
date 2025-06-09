extends Node

func disconnect_all_signals(obj : Object) -> void:
	for sig : Dictionary[String, Variant] in obj.get_signal_list():
		disconnect_connections(sig["signal"])
	return

func disconnect_connections(sig : Signal) -> void:
	for connection : Dictionary in sig.get_connections():
		sig.disconnect(connection["callable"])
	return

func mass_equal(dataset_1 : Array[Variant], dataset_2 : Array[Variant]) -> bool:
	for i : int in range(0, min(len(dataset_1), len(dataset_2))):
		if not dataset_1[i] == dataset_2[i]:
			return false
	return true

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
		res += num + "."
	return res.left(-1)

func open_background_and_panel(state : bool, background : ColorRect, panel : PanelContainer) -> void:
	background.visible = true
	const values : Array[Vector2i] = [Vector2i(1, 0), Vector2i(135, 170)]
	create_tween().tween_property(background, "modulate:a", values[0][int(!state)], 0.15).from(values[0][int(state)])
	create_tween().tween_property(panel, "modulate:a", values[0][int(!state)], 0.15).from(values[0][int(state)])
	await create_tween().tween_property(panel, "position:y", values[1][int(!state)], 0.15).from(values[1][int(state)]).finished
	if not state:
		background.visible = false
	return

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

func create_gdscript(code : String) -> GDScript:
	var script : GDScript = GDScript.new()
	script.source_code = code
	script.reload()
	return script
