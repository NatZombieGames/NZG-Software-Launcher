extends Node
##The manager of everything relating to the user and settings alongside the [member error_log]

##The default path to save and load user data from, equal to;[br][codeblock](OS.get_executable_path().get_base_dir() + "/NSL_Data.dat")[/codeblock]
@onready var default_data_path : String = (OS.get_executable_path().get_base_dir() + "/NSL_Data.dat")
##The users platform using the [enum APIManager.platforms] enum
@export var platform : APIManager.platforms = APIManager.platforms.UNKNOWN
##The users settings
@export var settings : Dictionary[StringName, Variant] = {
	&"ColourSettings": {}, 
	&"ItchAPIKey": "", 
	&"DownloadMaximumPacketSize": 100_000, 
	&"ShowAppBackground": true, 
	&"CloseOnAppLaunch": false, 
	&"ProductToInstallLocation": {}, 
	&"ProductShortcuts": [], 
	&"InfoForNerds": false, 
	&"AlwaysWriteErrorLog": false, 
}
@export var new_user : bool = false
##The current error log, also see [method write_error_log] and [error_log_item]
var error_log : Array[error_log_item] = []
##For all the [enum APIManager.api]'s that require keys; returns the name of the settings for said key
const api_to_api_key_setting_name : Dictionary[APIManager.api, StringName] = {
	APIManager.api.ITCH: &"ItchAPIKey", 
}
##The items making up the contents of the [member error_log], each having a type, description and optional details alongside recording the time they were created[br][br]Also see [method write_error_log]
class error_log_item:
	##The time this log was written
	var time : float
	##The type or title of this error
	var error_type : String
	##The errors description
	var error_description : String
	##Any other details about the error, optional
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

##Appends a new [error_log_item] to the error log with the given [param type], [param description] and optional [param details]
func append_to_error_log(type : String, description : String, details : Dictionary[String, Variant] = {}) -> void:
	error_log.append(error_log_item.new(type, description, details))
	return

##Writes the error log to a file and returns the path of the file it was written to[br][br]It is written to[codeblock]OS.get_executable_path().get_base_dir() + "/NSLErrorLogs/NSL_ERROR_LOG_" + str(int(Time.get_unix_time_from_system())) + ".txt"[/codeblock]
func write_error_log() -> String:
	var text : String = "T[" + str(Time.get_unix_time_from_system()) + "]:Log Start\n\n"
	var to_append : String
	var keys : PackedStringArray
	var d2_keys : PackedStringArray
	var start : String
	var ending : String
	for item : error_log_item in error_log:
		# ├ └ ┬ │ ─
		to_append = "T[" + str(item.time) + "]:\n├───Type: " + item.error_type + "\n" + ["└", "├"][int(len(item.error_details.keys()) > 0)] + "───Description: " + item.error_description + "\n"
		if len(item.error_details.keys()) > 0:
			to_append += "└───Details:\n"
			keys = item.error_details.keys()
			for key : String in keys:
				start = "    " + ["├", "└"][int(keys.find(key) == (len(keys) - 1))] + "───" + key.capitalize() + ": "
				ending = " (" + str(item.error_details[key]) + ")\n"
				match key:
					"product":
						to_append += start + APIManager.product.find_key(item.error_details[key]) + ending
					"api":
						to_append += start + APIManager.api.find_key(item.error_details[key]) + ending
					"failure":
						to_append += start + APIManager.failures.find_key(item.error_details[key]) + ending
					"return_type":
						to_append += start + APIManager.return_types.find_key(item.error_details[key]) + ending
					"info", "info_type":
						to_append += start + APIManager.info_types.find_key(item.error_details[key]) + ending
					"batch", "batch_type":
						to_append += start + APIManager.batch_types.find_key(item.error_details[key]) + ending
					"platform":
						to_append += start + APIManager.platforms.find_key(item.error_details[key]) + ending
					_:
						if typeof(item.error_details[key]) == TYPE_DICTIONARY:
							to_append += start + "\n"
							d2_keys = item.error_details[key].keys()
							for key2 : String in d2_keys:
								to_append += "    " + ["│", " "][int(keys.find(key) == (len(keys) - 1))] + "   " + ["├", "└"][int(d2_keys.find(key2) == (len(d2_keys) - 1))] + "───" + key2.capitalize() + ": " + str(item.error_details[key][key2]) + "\n"
						else:
							to_append += start + str(item.error_details[key]) + "\n"
		text += to_append + "\n"
	text += "\nT[" + str(Time.get_unix_time_from_system()) + "]:Log End"
	if not DirAccess.dir_exists_absolute(OS.get_executable_path().get_base_dir() + "/NSLErrorLogs"):
		DirAccess.make_dir_absolute(OS.get_executable_path().get_base_dir() + "/NSLErrorLogs")
	var fname : String = OS.get_executable_path().get_base_dir() + "/NSLErrorLogs/NSL_ERROR_LOG_" + str(int(Time.get_unix_time_from_system())) + ".txt"
	var file : FileAccess = FileAccess.open(fname, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("!! Wrote error log to: '" + fname + "'.")
	return fname

##Saves the user data to the given [param path] which is by default [member default_data_path]
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

##Loads the user data from the given [param path] which is by default the [member default_data_path]
func load_data(path : String = default_data_path) -> void:
	new_user = true
	if not FileAccess.file_exists(path):
		print("!! Unable to load data from: '" + path + "' as there is no file there.")
		append_to_error_log("Data-Loading Failure", "When attempting to load data the given file didn't exist", {"path": path, "exists": FileAccess.file_exists(path), "files_at_base_dir": DirAccess.get_files_at(path.get_base_dir()), "data": settings})
		return
	if not path.get_extension() == "dat" and path.get_file().get_basename() == "NSL_Data":
		print("!! Unable to load data from: '" + path + "' as either the extension or filename don't match the required values.")
		append_to_error_log("Data-Loading Failure", "Invalid destined file during data loading", {"path": path, "exists": FileAccess.file_exists(path), "files_in_base_dir": DirAccess.get_files_at(path.get_base_dir()), "data": settings})
		return
	new_user = false
	var config : ConfigFile = ConfigFile.new()
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
	config.parse(file.get_as_text())
	print("\n")
	Array(config.get_section_keys(&"Data")).map(func(key : String) -> String: print(key + ": '" + str(config.get_value(&"Data", str(key))) + "'"); return key)
	print("\n")
	for key : StringName in settings.keys():
		settings.set(key, config.get_value(&"Data", key, settings[key]))
	file.close()
	UserManager.settings[&"ProductShortcuts"] = UserManager.settings[&"ProductShortcuts"].filter(func(item : String) -> bool: return item in APIManager.product.keys() and item != "UNKNOWN")
	print("! Succesfully loaded data from: '" + path + "'.")
	append_to_error_log("User-Manager Notification", "Loaded user data", {"path": path, "data": settings})
	return
