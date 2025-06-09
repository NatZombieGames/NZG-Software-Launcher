extends Node

@onready var default_data_path : String = (OS.get_executable_path().get_base_dir() + "/NSL_Data.dat")
@export var platform : APIManager.platforms = APIManager.platforms.UNKNOWN
@export var settings : Dictionary[StringName, Variant] = {
	&"ColourSettings": {}, 
	&"DefaultDownloadLocation": "", 
	&"ItchAPIKey": "", 
	&"DownloadMaximumPacketSize": 100_000, 
	&"ShowAppBackground": true, 
	&"CloseOnAppLaunch": false, 
	&"ProductToInstallLocation": {}, 
	&"ProductShortcuts": [], 
	&"InfoForNerds": false, 
	&"AlwaysWriteErrorLog": false, 
}
var error_log : Array[error_log_item] = []
const api_to_api_key_setting_name : Dictionary[APIManager.api, StringName] = {
	APIManager.api.ITCH: &"ItchAPIKey", 
}
class error_log_item:
	var time : float
	var error_type : String
	var error_description : String
	var error_details : Dictionary[String, Variant]
	func _init(type : String, desc : String, dets : Dictionary[String, Variant]) -> void:
		error_type = type
		error_description = desc
		error_details = dets
		time = Time.get_unix_time_from_system()
		return

func _init() -> void:
	settings[&"ColourSettings"] = ColourManager.get_colour_settings()
	match OS.get_name():
		"Windows":
			platform = APIManager.platforms.WINDOWS
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			platform = APIManager.platforms.LINUX
		_:
			platform = APIManager.platforms.UNKNOWN
	append_to_error_log("Launcher Info", "Launcher info", {"launcher_version": ProjectSettings.get_setting("application/config/version", "defaulted"), "os": OS.get_name(), "platform": platform, "launch_time": Time.get_unix_time_from_system(), "launch_date": Time.get_datetime_string_from_system(), "godot_version": Engine.get_version_info(), "architecture": Engine.get_architecture_name()})
	return

func _notification(notif : int) -> void:
	match notif:
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_data()
			append_to_error_log("User-Manager Notification", "Finished saving data after receiving NOTIFICATION_WM_CLOSE_REQUEST", {})
			if settings[&"AlwaysWriteErrorLogs"]:
				write_error_log()
		NOTIFICATION_CRASH:
			append_to_error_log("! Crash !", "Received crash notification")
			write_error_log()
	return

func append_to_error_log(type : String, description : String, details : Dictionary[String, Variant] = {}) -> void:
	error_log.append(error_log_item.new(type, description, details))
	return

func write_error_log() -> void:
	var text : String = "T[" + str(Time.get_unix_time_from_system()) + "]:Log Start\n\n"
	var to_append : String = ""
	for item : error_log_item in error_log:
		to_append = "T[" + str(item.time) + "]:\n----Type: " + item.error_type + "\n----Description: " + item.error_description + "\n"
		if len(item.error_details.keys()) > 0:
			to_append += "----Details:\n"
			for key : String in item.error_details:
				match key:
					"product":
						to_append += "------" + key.capitalize() + ": " + APIManager.product.find_key(item.error_details[key]) + " (" + str(item.error_details[key]) + ")\n"
					"api":
						to_append += "------" + key.capitalize() + ": " + APIManager.api.find_key(item.error_details[key]) + " (" + str(item.error_details[key]) + ")\n"
					"failure":
						to_append += "------" + key.capitalize() + ": " + APIManager.failures.find_key(item.error_details[key]) + " (" + str(item.error_details[key]) + ")\n"
					"return_type":
						to_append += "------" + key.capitalize() + ": " + APIManager.return_types.find_key(item.error_details[key]) + " (" + str(item.error_details[key]) + ")\n"
					"info", "info_type":
						to_append += "------" + key.capitalize() + ": " + APIManager.info_types.find_key(item.error_details[key]) + " (" + str(item.error_details[key]) + ")\n"
					"platform":
						to_append += "------" + key.capitalize() + ": " + APIManager.platforms.find_key(item.error_details[key]) + " (" + str(item.error_details[key]) + ")\n"
					_:
						to_append += "------" + key.capitalize() + ": " + str(item.error_details[key]) + "\n"
		text += to_append + "\n"
	text += "\nT[" + str(Time.get_unix_time_from_system()) + "]:Log End"
	var fname : String = OS.get_executable_path().get_base_dir() + "/NSL_ERROR_LOG_" + str(int(Time.get_unix_time_from_system())) + ".txt"
	var file : FileAccess = FileAccess.open(fname, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("!! Wrote error log to: '" + fname + "'.")
	return

func save_data(path : String = default_data_path) -> void:
	var config : ConfigFile = ConfigFile.new()
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_DEFLATE)
	settings[&"ColourSettings"] = ColourManager.get_colour_settings()
	for key : StringName in settings.keys():
		config.set_value(&"Data", str(key), settings[key])
	file.store_string(config.encode_to_text())
	file.close()
	append_to_error_log("User-Manager Notification", "Saved user data", {"path": path, "data": settings})
	print("! Saved data succesfully to: '" + path + "'.")
	return

func load_data(path : String = default_data_path) -> void:
	if not FileAccess.file_exists(path):
		print("!! Unable to load data from: '" + path + "' as there is no file there.")
		append_to_error_log("Data-Loading Failure", "When attempting to load data the given file didn't exist", {"path": path, "exists": FileAccess.file_exists(path), "files_at_base_dir": DirAccess.get_files_at(path.get_base_dir()), "data": settings})
		return
	if not path.get_extension() == "dat" and path.get_file().get_basename() == "NSL_Data":
		print("!! Unable to load data from: '" + path + "' as either the extension or filename don't match the required values.")
		append_to_error_log("Data-Loading Failure", "Invalid destined file during data loading", {"path": path, "exists": FileAccess.file_exists(path), "files_in_base_dir": DirAccess.get_files_at(path.get_base_dir()), "data": settings})
		return
	var config : ConfigFile = ConfigFile.new()
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
	config.parse(file.get_as_text())
	print("\n")
	Array(config.get_section_keys(&"Data")).map(func(key : String) -> String: print(key + ": '" + str(config.get_value(&"Data", str(key))) + "'"); return key)
	print("\n")
	for key : StringName in settings.keys():
		settings.set(key, config.get_value(&"Data", key, settings[key]))
	file.close()
	print("! Succesfully loaded data from: '" + path + "'.")
	append_to_error_log("User-Manager Notification", "Loaded user data", {"path": path, "data": settings})
	return
