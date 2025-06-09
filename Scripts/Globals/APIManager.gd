extends Node

var main : Control
var latest_version_cache : Dictionary[StringName, response] = {}
var download_url_cache : Dictionary[StringName, response] = {}
var executable_size_cache : Dictionary[StringName, response] = {}
var valid_api_key_cache : Dictionary[api, bool] = {}
var download_progress : int = 0
var download_size : int = 0
var last_packet_size : int = 0
var request_host : String = ""
var mutexes : Dictionary[mutex_type, Mutex] = {
	mutex_type.DOWNLOAD_PROGRESS: Mutex.new(), 
	mutex_type.DOWNLOAD_SIZE: Mutex.new(), 
	mutex_type.LAST_PACKET_SIZE: Mutex.new(), 
	mutex_type.REQUEST_HOST: Mutex.new(), 
}
const api_to_api_url : Dictionary[api, String] = {
	api.GITHUB: "https://api.github.com", 
	api.ITCH: "https://itch.io"
}
const api_to_api_name : Dictionary[api, String] = {
	api.GITHUB: "GitHub", 
	api.ITCH: "Itch.io", 
}
const api_requires_key : Dictionary[api, bool] = {
	api.GITHUB: false, 
	api.ITCH: true, 
}
## In order of API enum.
const product_to_api_availability : Dictionary[product, Array] = {
	product.NPS: [true, false], 
	product.NMP: [true, true], 
	product.MINING_IDLE: [false, true], 
	product.UNKNOWN: [false, false], 
}
## In order of API enum.
const product_to_source : Dictionary[product, Array] = {
	product.NPS: ["https://github.com/NatZombieGames/Nat-Password-Software", ""], 
	product.NMP: ["https://github.com/NatZombieGames/Nat-Music-Programme", "https://natzombiegames.itch.io/nat-music-programme"], 
	product.MINING_IDLE: ["", "https://natzombiegames.itch.io/mining-idle"], 
	product.UNKNOWN: ["", ""], 
}
const github_product_to_github_name : Dictionary[product, String] = {
	product.NPS: "Nat-Password-Software", 
	product.NMP: "Nat-Music-Programme", 
}
const itch_product_to_itch_id : Dictionary[product, String] = {
	product.NMP: "3398181", 
	product.MINING_IDLE: "3095012", 
}
const product_to_product_categories : Dictionary[product, Array] = {
	product.NPS: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.NMP: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.MINING_IDLE: [product_category.GAME], 
}
const product_to_name : Dictionary[product, String] = {
	product.NPS: "Nat Password Software", 
	product.NMP: "Nat Music Programme", 
	product.MINING_IDLE: "Mining Idle", 
}
const connection_timeout_threshold : int = 5
const connection_max_retries : int = 2
const connection_max_redirects : int = 5
enum api {GITHUB, ITCH, UNKNOWN}
enum product {NPS, NMP, MINING_IDLE, UNKNOWN}
enum product_category {SOFTWARE, GAME, OPEN_SOURCE}
enum mutex_type {DOWNLOAD_PROGRESS, DOWNLOAD_SIZE, LAST_PACKET_SIZE, REQUEST_HOST}
enum failures {
	UNKNOWN, 
	NONE, 
	CONNECTION_FAILED, 
	TIMEOUT, 
	REDIRECT, 
	RATE_LIMITED, 
	UNHANDLED_STATUS_OR_CODE_RETURNED, 
	INVALID_HOST, 
	INVALID_KEY, 
	UNREADABLE_KEY, 
	NO_AVAILABLE_API, 
	INVALID_SELECTION, 
	}
enum return_types {STR, BYT}
enum info_types {LATEST_VERSION, DOWNLOAD_URL, EXECUTABLE_SIZE}
enum platforms {WINDOWS, LINUX, UNKNOWN}
class response:
	var success : bool
	var failure : failures
	var details : Dictionary[String, Variant]
	var return_type : return_types
	var returned_str : String
	var returned_byt : PackedByteArray
	func _init(nsuccess : bool = false, nfailure : failures = failures.UNKNOWN, ndetails : Dictionary[String, Variant] = {}, nreturn_type : return_types = return_types.STR, nreturned_str : String = "", nreturned_byt : PackedByteArray = []) -> void:
		success = nsuccess
		failure = nfailure
		details = ndetails
		return_type = nreturn_type
		returned_str = nreturned_str
		returned_byt = nreturned_byt
		return
	func _get_details() -> void:
		print("---\n- Success: " + str(success).capitalize() + "\n- Failure: " + str(failures.find_key(failure)).capitalize() + "\n- Details:\n-- " + str(details) + "\n- Returned Type: " + return_types.find_key(return_type) + "\n- Returned Str: " + returned_str + "\n- Returned Bytes?: " + str(len(returned_byt) > 0) + "\n---")
		return

func _create_cache_key(target : api, prod : product) -> StringName:
	return StringName(String.num_uint64(target, 2).lpad(8, "0") + "|" + String.num_uint64(prod, 2).lpad(8, "0"))

func get_available_api(prod : product) -> api:
	if true in product_to_api_availability[prod]:
		@warning_ignore("int_as_enum_without_cast")
		return product_to_api_availability[prod].find(true)
	return api.UNKNOWN

func is_available_in_api(prod : product, app : api) -> bool:
	return product_to_api_availability.get(prod, [false, false])[app]

func fetch_info(prod : product, info : info_types) -> response:
	if prod == product.UNKNOWN:
		_report_failure("Fetch Failure", "When attempting to fetch info of type: '" + info_types.find_key(info) + "' about a product the product was unknown", {"product": prod, "info": info}, true)
		return response.new(false, failures.INVALID_SELECTION)
	var target : api = get_available_api(prod)
	if target == api.UNKNOWN:
		_report_failure("Fetch Failure", "When attempting to fetch info of type: '" + info_types.find_key(info) + "' about the product: '" + product.find_key(prod) + "' no available API was found", {"product": prod, "info": info}, true)
		return response.new(false, failures.NO_AVAILABLE_API)
	var cache_key : StringName = _create_cache_key(target, prod)
	var cache_response : response
	match info:
		info_types.DOWNLOAD_URL:
			if cache_key in download_url_cache.keys() and download_url_cache[cache_key].success:
				cache_response = latest_version_cache[cache_key]
		info_types.LATEST_VERSION:
			if cache_key in latest_version_cache.keys() and latest_version_cache[cache_key].success:
				cache_response = latest_version_cache[cache_key]
		info_types.EXECUTABLE_SIZE:
			if cache_key in executable_size_cache.keys() and executable_size_cache[cache_key].success:
				cache_response = executable_size_cache[cache_key]
	if cache_response:
		cache_response.details["cached"] = true
		return cache_response
	var fetch_response : response = response.new()
	var details : Dictionary[String, Variant] = {
		"connection_response": null, 
		"request_response": null, 
		"key_response": null, 
		"version": "", 
	}
	var url : String = ""
	var headers : PackedStringArray = []
	var body : String = ""
	match target:
		api.ITCH:
			var key_response : response = validate_key(api.ITCH)
			details["key_response"] = key_response
			if not key_response.success:
				if key_response.failure == failures.INVALID_KEY:
					_report_failure("Fetch Failure", "Tried to access an Itch.io product and the Itch.io key was found to be invalid", {"product": prod, "info": info, "api": target, "failure": key_response.failure, "details": key_response.details, "returned_str": key_response.returned_str, "key": UserManager.settings[&"ItchAPIKey"]})
				else:
					_report_failure("Fetch Failure", "An error occured when attempting to validate an Itch.io key when trying to access an Itch.io product", {"product": prod, "info": info, "api": target, "failure": key_response.failure, "details": key_response.details, "returned_str": key_response.returned_str, "key": UserManager.settings[&"ItchAPIKey"]})
				return response.new(false, key_response.failure, details)
			url = "/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/game/" + itch_product_to_itch_id[prod] + "/uploads"
			headers = ["accept:json"]
			body = ""
		api.GITHUB:
			url = "/repos/NatZombieGames/" + github_product_to_github_name[prod] + "/releases/latest"
			headers = ["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"]
			body = '{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}'
	var request_response : response = _request_url(url, headers, body, api_to_api_url[target])
	if not request_response.success:
		print("Fetch info failed.")
		_report_failure("Fetch Failure", "When attempting to fetch the info: '" + info_types.find_key(info) + "' an error occured when fetching from the url", {"product": prod, "info": info, "api": target, "failure": request_response.failure, "details": request_response.details, "url": url, "headers": headers, "body": body, "host": api_to_api_url[target]})
		return response.new(false, request_response.failure, details)
	details["request_response"] = request_response
	var response_json : Dictionary[String, Variant]
	response_json.assign(JSON.parse_string(request_response.returned_str))
	match target:
		api.ITCH:
			details["version"] = response_json["uploads"][0]["display_name"]
			details["version"] = details["version"].right(len(details["version"]) - 1 - details["version"].to_lower().rfind("v"))
			match info:
				info_types.LATEST_VERSION:
					fetch_response.returned_str = details["version"]
				info_types.DOWNLOAD_URL:
					for upload : Dictionary in response_json["uploads"]:
						if [upload["p_windows"], upload["p_linux"], true][UserManager.platform] == true:
							upload["id"] = int(upload["id"])
							fetch_response.returned_str = "https://itch.io/api/1/" + str(UserManager.settings[&"ItchAPIKey"]) + "/upload/" + str(upload["id"]) + "/download"
							details["upload_id"] = upload["id"]
				info_types.EXECUTABLE_SIZE:
					for upload : Dictionary in response_json["uploads"]:
						if [upload["p_windows"], upload["p_linux"], true][UserManager.platform] == true:
							fetch_response.returned_str = str(upload["size"])
							details["upload_id"] = int(upload["id"])
		api.GITHUB:
			details["version"] = response_json["tag_name"]
			match info:
				info_types.LATEST_VERSION:
					fetch_response.returned_str = details["version"]
				info_types.DOWNLOAD_URL:
					for asset : Dictionary in response_json["assets"]:
						if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe"), true][UserManager.platform]:
							fetch_response.returned_str = asset["browser_download_url"]
				info_types.EXECUTABLE_SIZE:
					for asset : Dictionary in response_json["assets"]:
						if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe"), true][UserManager.platform]:
							fetch_response.returned_str = str(asset["size"])
	fetch_response.details = details
	fetch_response.success = true
	fetch_response.failure = failures.NONE
	match info:
		info_types.LATEST_VERSION:
			latest_version_cache[cache_key] = fetch_response
		info_types.DOWNLOAD_URL:
			download_url_cache[cache_key] = fetch_response
		info_types.EXECUTABLE_SIZE:
			executable_size_cache[cache_key] = fetch_response
	return fetch_response

func download_executable(prod : product) -> response:
	if prod == product.UNKNOWN:
		_report_failure("Download Failure", "When attempting to download an executable the given product was unknown", {"product": prod}, true)
		return response.new(false, failures.INVALID_SELECTION)
	var target : api = get_available_api(prod)
	if target == api.UNKNOWN:
		_report_failure("Download Failure", "When attempting to get an available API for the product: '" + product.find_key(prod) + "' no available API was found", {"product": product, "api": target}, true)
		return response.new(false, failures.INVALID_SELECTION)
	var download_response : response = response.new()
	var details : Dictionary[String, Variant] = {
		"request_response": null, 
		"download_attempt_response": null, 
		"size": 0, 
		"redirects": 0, 
	}
	var download_url : String
	var request_response : response = fetch_info(prod, info_types.DOWNLOAD_URL)
	if not request_response.success:
		_report_failure("Download Failure", "Failed to fetch the download url for the product: '" + product.find_key(prod) + "' during download_executable", {"product": prod, "api": target, "failure": request_response.failure, "details": request_response.details})
		return response.new(false, request_response.failure, details)
	details["request_response"] = request_response
	download_url = request_response.returned_str
	var download_attempt_response : response = response.new()
	var headers : PackedStringArray
	var body : String
	var return_type : return_types = return_types.STR
	match target:
		api.ITCH:
			headers = ["accept:json"]
			body = ""
		api.GITHUB:
			headers = ["X-GitHub-Api-Version:2022-11-28"]
			body = '{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}'
	var start_time : float = Time.get_unix_time_from_system()
	for i : int in range(0, connection_max_redirects):
		details["redirects"] = i
		var download_thread : Thread = Thread.new()
		download_thread.start(Callable(self, &"_request_url").bindv(
			[download_url, headers, body, api_to_api_url[target], return_type]))
		while download_thread.is_alive():
			for mtx : mutex_type in mutex_type.values():
				mutexes[mtx].lock()
			main.update_download_visuals(product_to_name[prod], request_response.details["version"], platforms.find_key(UserManager.platform), api_to_api_name[target], download_size, Time.get_unix_time_from_system() - start_time, download_progress, last_packet_size, request_host)
			details["size"] = download_size
			for mtx : mutex_type in mutex_type.values():
				mutexes[mtx].unlock()
			await get_tree().process_frame
		download_attempt_response = download_thread.wait_to_finish()
		details["download_attempt_response"] = download_attempt_response
		download_response.details = details
		match target:
			api.ITCH:
				if not download_attempt_response.success:
					_report_failure("Download Failure", "An error occured when downloading an executable", {"product": prod, "api": target, "failure": download_attempt_response.failure, "details": download_attempt_response.details})
					return download_response
				match i:
					0:
						var json : Dictionary[String, String]
						json.assign(JSON.parse_string(download_attempt_response.returned_str))
						download_url = json["url"]
						return_type = return_types.BYT
					1:
						download_response.returned_byt = download_attempt_response.returned_byt
						download_response.success = true
						download_response.failure = failures.NONE
						return download_response
			api.GITHUB:
				if download_attempt_response.success:
					download_response.returned_byt = download_attempt_response.returned_byt
					download_response.success = true
					download_response.failure = failures.NONE
					return download_response
				if download_attempt_response.failure == failures.REDIRECT:
					match i:
						0:
							download_url = download_attempt_response.details["ending_response_headers"][4].right(-10)
							return_type = return_types.BYT
				else:
					_report_failure("Download Failure", "An error occured when downloading an executable", {"product": prod, "api": target, "failure": download_attempt_response.failure, "details": download_attempt_response.details})
					return download_response
	download_response.details = details
	return download_response

func validate_key(target : api) -> response:
	if target in valid_api_key_cache.keys() and valid_api_key_cache:
		return response.new(true, failures.NONE)
	if not api_requires_key[target]:
		return response.new(true, failures.NONE)
	var key_response : response = response.new()
	var details : Dictionary[String, Variant] = {
		"request_response": null, 
	}
	match target:
		api.ITCH:
			if UserManager.settings[&"ItchAPIKey"] == "":
				_report_failure("Key Validation Failure", "When attempting to validate Itch.io key it was unreadable", {"api": target, "key": UserManager.settings[&"ItchAPIKey"]})
				return response.new(false, failures.UNREADABLE_KEY, details)
			var request_response : response = _request_url(
				"/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/credentials/info", 
				["accept:json"], 
				"", 
				api_to_api_url[target]
				)
			details["request_response"] = request_response
			if not request_response.success:
				_report_failure("Key Validation Failure", "An error occured when attempting to validate the Itch.io key", {"api": target, "failure": request_response.failure, "details": request_response.details, "key": UserManager.settings[&"ItchAPIKey"]})
				return response.new(false, request_response.failure, details)
			var json : Dictionary[String, String]
			json.assign(JSON.parse_string(request_response.returned_str))
			if json["type"] == "key":
				valid_api_key_cache[target] = true
				key_response.success = true
				key_response.failure = failures.NONE
				key_response.details = details
				return key_response
			else:
				_report_failure("Key Validation Failure", "The Itch.io key was found to be invalid", {"api": target, "returned_str": request_response.returned_str, "key": UserManager.settings[&"ItchAPIKey"]})
				main.create_alert("Key Validation Failure", "Your Itch.io key was found to be invalid;\nplease check it and try again.")
				return response.new(false, failures.INVALID_KEY, details)
	return response.new()

func _connect_to_host(host : String, client : HTTPClient) -> response:
	var attempt_start_time : float
	var attempt : bool
	var details : Dictionary[String, Variant] = {
		"timed_out": false, 
		"attempt_start_time": 0.0, 
		"attempt_end_time": 0.0, 
		"attempt_time": 0.0, 
		"attempts": 0, 
		"ending_http_status": 0, 
	}
	var connection_response : response = response.new()
	for i : int in range(0, connection_max_retries):
		client.close()
		client.connect_to_host(host)
		attempt = true
		attempt_start_time = Time.get_unix_time_from_system()
		details["attempt_start_time"] = attempt_start_time
		details["attempts"] = i + 1
		while attempt:
			client.poll()
			match client.get_status():
				HTTPClient.STATUS_CONNECTED:
					details["attempt_end_time"] = Time.get_unix_time_from_system()
					details["attempt_time"] = details["attempt_end_time"] - details["attempt_start_time"]
					details["ending_http_status"] = HTTPClient.STATUS_CONNECTED
					connection_response.details = details
					connection_response.success = true
					connection_response.failure = failures.NONE
					return connection_response
				HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING:
					attempt = (Time.get_unix_time_from_system() - attempt_start_time) < connection_timeout_threshold
					details["timed_out"] = !attempt
					if not attempt:
						connection_response.failure = failures.TIMEOUT
				_:
					connection_response.failure = failures.UNHANDLED_STATUS_OR_CODE_RETURNED
					attempt = false
		details["attempt_end_time"] = Time.get_unix_time_from_system()
		details["attempt_time"] = details["attempt_end_time"] - details["attempt_start_time"]
		details["ending_http_status"] = client.get_status()
	connection_response.details = details
	connection_response.success = false
	_report_failure("Host-Connection Failure", "An error occured when attempting to connect to a host", {"host": host, "failure": connection_response.failure, "details": connection_response.details})
	return connection_response

func _request_url(url : String, headers : PackedStringArray, body : String, host : String = "", return_type : return_types = return_types.STR) -> response:
	var client : HTTPClient = HTTPClient.new()
	client.read_chunk_size = UserManager.settings[&"DownloadMaximumPacketSize"]
	if url.begins_with("https://"):
		host = url.left(8 + len(url.right(-8).get_slice("/", 0)))
		url = url.right(len(host) * -1)
	if host == "":
		_report_failure("URL-Request Failure", "An invalid host was given when trying to request from a url", {"url": url, "headers": headers, "body": body, "host": host, "return_type": return_type})
		return response.new(false, failures.INVALID_HOST)
	mutexes[mutex_type.REQUEST_HOST].lock()
	request_host = host
	mutexes[mutex_type.REQUEST_HOST].unlock()
	var request_response : response = response.new()
	request_response.return_type = return_type
	var attempt_start_time : float
	var attempt : bool
	var details : Dictionary[String, Variant] = {
		"timed_out": false, 
		"attempt_start_time": 0.0, 
		"attempt_end_time": 0.0, 
		"attempt_time": 0.0, 
		"attempts": 0, 
		"ending_http_status": 0, 
		"ending_response_code": 0, 
		"ending_response_headers": [], 
		"response_length": 0, 
		"redirected": false, 
	}
	mutexes[mutex_type.DOWNLOAD_SIZE].lock()
	mutexes[mutex_type.DOWNLOAD_PROGRESS].lock()
	download_size = 0
	download_progress = 0
	mutexes[mutex_type.DOWNLOAD_SIZE].unlock()
	mutexes[mutex_type.DOWNLOAD_PROGRESS].unlock()
	for i : int in range(0, connection_max_retries):
		var connection_attempt : response = _connect_to_host(host, client)
		if not connection_attempt.success:
			_report_failure("URL-Request Failure", "Unable to connect to host during url request", {"url": url, "headers": headers, "body": body, "host": host, "return_type": return_type, "failure": connection_attempt.failure, "details": connection_attempt.details})
			return response.new(false, failures.CONNECTION_FAILED, {"connection_response": connection_attempt})
		client.request(HTTPClient.METHOD_GET, url, headers, body)
		attempt_start_time = Time.get_unix_time_from_system()
		attempt = true
		details["attempt_start_time"] = attempt_start_time
		details["attempts"] = i + 1
		while attempt:
			client.poll()
			match client.get_status():
				HTTPClient.STATUS_BODY:
					match client.get_response_code():
						HTTPClient.RESPONSE_OK:
							request_response.success = true
							request_response.failure = failures.NONE
							details["attempt_end_time"] = Time.get_unix_time_from_system()
							details["attempt_time"] = details["attempt_end_time"] - details["attempt_start_time"]
							details["ending_http_status"] = client.get_status()
							details["ending_response_code"] = client.get_response_code()
							details["ending_response_headers"] = client.get_response_headers()
							mutexes[mutex_type.DOWNLOAD_SIZE].lock()
							download_size = client.get_response_body_length()
							mutexes[mutex_type.DOWNLOAD_SIZE].unlock()
							main.downloading_mutex.lock()
							main.downloading = true
							main.downloading_mutex.unlock()
							match return_type:
								return_types.STR:
									var resp : String = ""
									while len(resp) < maxi(1, client.get_response_body_length()):
										resp += client.read_response_body_chunk().get_string_from_utf8()
										mutexes[mutex_type.DOWNLOAD_PROGRESS].lock()
										mutexes[mutex_type.LAST_PACKET_SIZE].lock()
										last_packet_size = len(resp) - download_progress
										download_progress = len(resp)
										mutexes[mutex_type.DOWNLOAD_PROGRESS].unlock()
										mutexes[mutex_type.LAST_PACKET_SIZE].unlock()
									request_response.returned_str = resp
									details["response_length"] = len(resp)
								return_types.BYT:
									var resp : PackedByteArray = []
									while len(resp) < maxi(1, client.get_response_body_length()):
										resp.append_array(client.read_response_body_chunk())
										mutexes[mutex_type.DOWNLOAD_PROGRESS].lock()
										download_progress = len(resp)
										mutexes[mutex_type.DOWNLOAD_PROGRESS].unlock()
									request_response.returned_byt = resp
									details["response_length"] = len(resp)
							request_response.details = details
							main.downloading_mutex.lock()
							main.downloading = false
							main.downloading_mutex.unlock()
							return request_response
						HTTPClient.RESPONSE_CONTINUE, HTTPClient.RESPONSE_PROCESSING:
							attempt = (Time.get_unix_time_from_system() - details["attempt_start_time"]) < connection_timeout_threshold
							details["timed_out"] = !attempt
							request_response.failure = failures.TIMEOUT
						HTTPClient.RESPONSE_FOUND:
							request_response.failure = failures.REDIRECT
							details["redirected"] = true
							attempt = false
						HTTPClient.RESPONSE_TOO_MANY_REQUESTS:
							request_response.failure = failures.RATE_LIMITED
							attempt = false
				HTTPClient.STATUS_REQUESTING:
					attempt = (Time.get_unix_time_from_system() - attempt_start_time) < connection_timeout_threshold
					details["timed_out"] = !attempt
					if not attempt:
						request_response.failure = failures.TIMEOUT
				_:
					request_response.failure = failures.UNHANDLED_STATUS_OR_CODE_RETURNED
					attempt = false
		details["attempt_end_time"] = Time.get_unix_time_from_system()
		details["attempt_time"] = details["attempt_end_time"] - details["attempt_start_time"]
		details["ending_http_status"] = client.get_status()
		details["ending_response_code"] = client.get_response_code()
		details["ending_response_headers"] = client.get_response_headers()
		if request_response.failure == failures.REDIRECT:
			request_response.success = false
			request_response.details = details
			return request_response
	request_response.success = false
	request_response.details = details
	_report_failure("URL-Request Failure", "Failed to request from url", {"url": url, "headers": headers, "body": body, "host": host, "return_type": return_type, "failure": request_response.failure, "details": request_response.details})
	return request_response

func _report_failure(type : String, description : String, details : Dictionary[String, Variant], alert : bool = false) -> void:
	UserManager.append_to_error_log(type, description, details)
	if alert:
		main.create_alert(type, "A failure occured when fetching information;\nplease check / report your error log from the settings.")
	return
