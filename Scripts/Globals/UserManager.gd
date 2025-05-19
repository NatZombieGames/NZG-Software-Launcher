extends Node

@onready var default_data_path : String = (OS.get_executable_path().get_base_dir() + "/NSL_Data.dat")
@export var platform : APIManager.platforms = APIManager.platforms.UNKNOWN
@export var settings : Dictionary[StringName, Variant] = {
	&"ColourSettings": {}, 
	&"DefaultDownloadLocation": "", 
	&"ItchAPIKey": "", 
	&"DownloadMaximumPacketSize": 100_000, 
	&"ProductToInstallLocation": {}, 
	&"ProductShortcuts": [], 
}

func _init() -> void:
	settings[&"ColourSettings"] = ColourManager.get_colour_settings()
	match OS.get_name():
		"Windows":
			platform = APIManager.platforms.WINDOWS
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			platform = APIManager.platforms.LINUX
		_:
			platform = APIManager.platforms.UNKNOWN
	return

func _notification(notif : int) -> void:
	match notif:
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_data()
	return

func save_data(path : String = default_data_path) -> void:
	var config : ConfigFile = ConfigFile.new()
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_DEFLATE)
	settings[&"ColourSettings"] = ColourManager.get_colour_settings()
	for key : StringName in settings.keys():
		config.set_value(&"Data", str(key), settings[key])
	file.store_string(config.encode_to_text())
	file.close()
	print("! Saved data succesfully to: '" + path + "'.")
	return

func load_data(path : String = default_data_path) -> void:
	if not FileAccess.file_exists(path):
		print("!! Unable to load data from: '" + path + "' as there is no file there.")
		return
	if not path.get_extension() == "dat" and path.get_file().get_basename() == "NSL_Data":
		print("!! Unable to load data from: '" + path + "' as either the extension or filename don't match the required values.")
		return
	var config : ConfigFile = ConfigFile.new()
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
	config.parse(file.get_as_text())
	print("\n")
	Array(config.get_section_keys(&"Data")).map(func(key : String) -> String: print(key + ": '" + str(config.get_value(&"Data", str(key))) + "'"); return key)
	print("\n")
	for key : StringName in config.get_section_keys(&"Data"):
		settings.set(key, config.get_value(&"Data", key, settings[key]))
	file.close()
	print("! Succesfully loaded data from: '" + path + "'.")
	return
