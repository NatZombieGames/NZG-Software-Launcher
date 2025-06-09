extends Node

var main : Control
var current_version : String = ""
var retrieved_latest_version_info : bool = false
var latest_version : String = ""
var latest_version_size : String = ""
const latest_version_url : String = "/repos/NatZombieGames/NZG-Software-Launcher/releases/latest"
const latest_version_headers : PackedStringArray = ["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"]
const latest_version_body : String = '{"owner":"natzombiegames","repo":"nzg_software_launcher"}'
const latest_version_host : String = "https://api.github.com"

func _init() -> void:
	current_version = ProjectSettings.get_setting("application/config/version", "0.0.0")
	return

func get_latest_version_info() -> void:
	retrieved_latest_version_info = false
	var response : APIManager.response = APIManager._request_url(
		latest_version_url, 
		latest_version_headers, 
		latest_version_body, 
		latest_version_host
		)
	if not response.success:
		print(APIManager.failures.find_key(response.failure).capitalize())
		_report_failure("Update-Manager Failure", "Failed to retrieve latest launcher version info", {"failure": response.failure, "details": response.details})
		return
	var json : Dictionary[String, Variant]
	json.assign(JSON.parse_string(response.returned_str))
	latest_version = json["tag_name"]
	for asset : Dictionary in json["assets"]:
		if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe"), true][UserManager.platform]:
			latest_version_size = str(asset["size"])
	retrieved_latest_version_info = true
	return

func download_latest_version() -> void:
	if not retrieved_latest_version_info:
		get_latest_version_info()
		if not retrieved_latest_version_info:
			_report_failure("Update-Manager Failure", "Can not download latest launcher version as the latest version info was unable to be retrieved", {})
			return
	var thread : Thread
	var response : APIManager.response
	var attempt : bool = true
	var attempt_number : int = 0
	var start_time : float = Time.get_unix_time_from_system()
	var url : String = latest_version_url
	var return_type : APIManager.return_types = APIManager.return_types.STR
	main.toggle_main_download_screen(true)
	while attempt:
		attempt_number += 1
		thread = Thread.new()
		thread.start(Callable(APIManager, &"_request_url").bindv(
			[url, latest_version_headers, latest_version_body, latest_version_host, return_type]))
		while thread.is_alive():
			_lock_download_mutexes()
			main.update_download_visuals("NZG Software Launcher", latest_version, APIManager.platforms.find_key(UserManager.platform), "GitHub", APIManager.download_size, Time.get_unix_time_from_system() - start_time, APIManager.download_progress, APIManager.last_packet_size, APIManager.request_host)
			_unlock_download_mutexes()
			await get_tree().process_frame
		response = thread.wait_to_finish()
		match attempt_number:
			1:
				if not response.success:
					attempt = false
					break
				var json : Dictionary[String, Variant]
				json.assign(JSON.parse_string(response.returned_str))
				for asset : Dictionary in json["assets"]:
					if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe"), true][UserManager.platform]:
						url = asset["browser_download_url"]
			2:
				if not response.failure == APIManager.failures.REDIRECT:
					attempt = false
					break
				url = response.details["ending_response_headers"][4].right(-10)
				return_type = APIManager.return_types.BYT
			3:
				main.loading = true
				await get_tree().process_frame
				var dir : String = OS.get_executable_path().get_base_dir()
				var ext : String = ["", ".exe"][int(UserManager.platform == APIManager.platforms.WINDOWS)]
				var new_name : String = str(randi_range(0, 10000000)).md5_text() + ext
				while new_name in DirAccess.get_files_at(dir):
					new_name = str(randi_range(0, 10000000)).md5_text() + ext
				var file : FileAccess = FileAccess.open(dir + "\\" + new_name, FileAccess.WRITE)
				file.store_buffer(response.returned_byt)
				file.close()
				OS.execute_with_pipe(dir + "\\" + new_name, ["kill_old_nsl_process=" + OS.get_executable_path()])
				get_tree().quit()
			_:
				attempt = false
				break
	print(APIManager.failures.find_key(response.failure).capitalize())
	_report_failure("Update-Manager Failure", "A failure occured when trying to download latest launcher version", {"failure": response.failure, "details": response.details})
	return

func _lock_download_mutexes() -> void:
	for mtx : APIManager.mutex_type in APIManager.mutex_type.values():
		APIManager.mutexes[mtx].lock()
	return

func _unlock_download_mutexes() -> void:
	for mtx : APIManager.mutex_type in APIManager.mutex_type.values():
		APIManager.mutexes[mtx].unlock()
	return

func _report_failure(type : String, description : String, details : Dictionary[String, Variant], alert : bool = false) -> void:
	UserManager.append_to_error_log(type, description, details)
	if alert:
		main.create_alert(type, "A failure occured when fetching information;\nplease check / report your error log from the settings.")
	return
