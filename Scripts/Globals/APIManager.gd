extends Node

var main : Control
var connection_statuses : Dictionary[api, connection_status] = {
	api.GITHUB: connection_status.NOT_ATTEMPTED, 
	api.ITCH: connection_status.NOT_ATTEMPTED, 
}
var clients : Dictionary[api, HTTPClient] = {
	api.GITHUB: HTTPClient.new(), 
	api.ITCH: HTTPClient.new(), 
}
var latest_version_cache : Dictionary[StringName, fetch_response] = {}
var valid_api_key_cache : Dictionary[api, bool] = {}
var current_task : task = task.INACTIVE
var download_progress : int = 0
var download_size : int = 0
var mutexes : Dictionary[mutex_type, Mutex] = {
	mutex_type.TASK: Mutex.new(), 
	mutex_type.DOWNLOAD_PROGRESS: Mutex.new(), 
	mutex_type.DOWNLOAD_SIZE: Mutex.new(), 
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
	product.NDP: [true, false], 
	product.MINING_IDLE: [false, true], 
	product.UNKNOWN: [false, false], 
}
## In order of API enum.
const product_to_source : Dictionary[product, Array] = {
	product.NPS: ["https://github.com/NatZombieGames/Nat-Password-Software", ""], 
	product.NMP: ["https://github.com/NatZombieGames/Nat-Music-Programme", "https://natzombiegames.itch.io/nat-music-programme"], 
	product.NDP: ["https://github.com/NatZombieGames/Nat-Documenter-Programme", ""], 
	product.MINING_IDLE: ["", "https://natzombiegames.itch.io/mining-idle"], 
	product.UNKNOWN: ["", ""], 
}
const github_product_to_github_name : Dictionary[product, String] = {
	product.NPS: "Nat-Password-Software", 
	product.NMP: "Nat-Music-Programme", 
	product.NDP: "Nat-Documenter-Programme", 
}
const itch_product_to_itch_id : Dictionary[product, String] = {
	product.NMP: "3398181", 
	product.MINING_IDLE: "3095012", 
}
const product_to_product_categories : Dictionary[product, Array] = {
	product.NPS: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.NMP: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.NDP: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.MINING_IDLE: [product_category.GAME], 
}
const product_to_name : Dictionary[product, String] = {
	product.NPS: "Nat Password Software", 
	product.NMP: "Nat Music Programme", 
	product.NDP: "Nat Documenter Programme", 
	product.MINING_IDLE: "Mining Idle", 
}
const connection_timeout_threshold : int = 5
enum api {GITHUB, ITCH, UNKNOWN}
enum product {NPS, NMP, NDP, MINING_IDLE, UNKNOWN}
enum product_category {SOFTWARE, GAME, OPEN_SOURCE}
enum mutex_type {TASK, DOWNLOAD_PROGRESS, DOWNLOAD_SIZE}
enum task {INACTIVE, CONNECTING, FETCHING, DOWNLOADING}
enum connection_status {CONNECTED, FAILED, TIMEOUT, CLOSED, NOT_ATTEMPTED}
enum fetch_status {RETRIEVED, FAILED, TIMEOUT}
enum key_validation_responses {VALID, INVALID, UNKNOWN}
enum key_validation_response_details {FAILED_TO_CONNECT, FAILED_TO_READ_RESPONSE, UNNECESSARY, UNREADABLE_KEY, INVALID_KEY, NONE}
enum info_types {UNKNOWN, LATEST_VERSION, EXECUTABLE_URL}
enum platforms {UNKNOWN, WINDOWS, LINUX}
class fetch_response:
	var status : fetch_status = fetch_status.FAILED
	var type : info_types = info_types.UNKNOWN
	var data : Dictionary[String, Variant] = {}
	var response : String = ""
	func _init(stat : fetch_status = fetch_status.FAILED, typ : info_types = info_types.UNKNOWN, resp : String = "", new_data : Dictionary[String, Variant] = {}) -> void:
		status = stat
		type = typ
		response = resp
		data = new_data
		return
	func _get_details() -> void:
		print("\n---\n-Status: " + fetch_status.find_key(status) + "\n-Type: " + info_types.find_key(type) + "\n-Data: " + str(data) + "\n-Response:\n-- " + response + "\n---\n")
		return
class key_validation_response:
	var response : key_validation_responses = key_validation_responses.UNKNOWN
	var details : key_validation_response_details = key_validation_response_details.NONE
	func _init(resp : key_validation_responses = key_validation_responses.UNKNOWN, dets : key_validation_response_details = key_validation_response_details.NONE) -> void:
		response = resp
		details = dets
		return
	func _get_details() -> void:
		print("\n---\n-Response: " + key_validation_responses.find_key(response) + "\n-Details: " + key_validation_response_details.find_key(details) + "\n---")
		return

func _notification(notif : int) -> void:
	match notif:
		Node.NOTIFICATION_WM_CLOSE_REQUEST:
			clean_up_clients()
	return

func _get_api_details(target : api) -> void:
	print("\n---\n-API: " + api.find_key(target) + "\n-Status: " + connection_status.find_key(connection_statuses[target]) + "\n-URL:\n-- " + api_to_api_url[target] + "\n---\n")
	return

func _create_cache_key(target : api, prod : product) -> StringName:
	return StringName(String.num_uint64(target, 2).lpad(8, "0") + "|" + String.num_uint64(prod, 2).lpad(8, "0"))

func get_available_api(prod : product) -> api:
	print("trying to get available api for " + product.find_key(prod) + " from list:\n", product_to_api_availability[prod])
	if true in product_to_api_availability[prod]:
		print("returning " + api.find_key(product_to_api_availability[prod].find(true)))
		@warning_ignore("int_as_enum_without_cast")
		return product_to_api_availability[prod].find(true)
	print("returning unknown")
	return api.UNKNOWN

func clean_up_clients() -> void:
	for target : api in api.values():
		if api.find_key(target) != "UNKNOWN":
			close_connection(target)
	return

func close_connection(target : api) -> void:
	clients[target].close()
	connection_statuses[target] = connection_status.CLOSED
	return

func is_available_in_api(prod : product, app : api) -> bool:
	return product_to_api_availability[prod][app]

func attempt_connection(target : api) -> connection_status:
	print("attempting to connect to " + api.find_key(target))
	if target == api.UNKNOWN:
		print("unable to connect as target is api.UNKNOWN")
		return connection_status.FAILED
	current_task = task.CONNECTING
	var client : HTTPClient = clients[target]
	client.close()
	client.connect_to_host(api_to_api_url[target])
	var continue_attempt : bool = true
	var attempt_start_time : float = Time.get_unix_time_from_system()
	var status : connection_status = connection_status.FAILED
	while continue_attempt:
		client.poll()
		match client.get_status():
			HTTPClient.Status.STATUS_CONNECTED:
				print("i have connected to " + api.find_key(target))
				continue_attempt = false
				status = connection_status.CONNECTED
			HTTPClient.Status.STATUS_RESOLVING, HTTPClient.Status.STATUS_CONNECTING:
				continue_attempt = (int(Time.get_unix_time_from_system() - attempt_start_time)) < connection_timeout_threshold
				if not continue_attempt:
					print("i timed out when connecting to " + api.find_key(target))
					status = connection_status.TIMEOUT
			_:
				print("!!! Connection Attempt To " + api.find_key(target) + " Failing status: ", client.get_status())
				continue_attempt = false
				status = connection_status.FAILED
	connection_statuses[target] = status
	_get_api_details(target)
	current_task = task.INACTIVE
	return status

func fetch_info(target : api, prod : product, info : info_types, exec_type : platforms = platforms.WINDOWS, get_from_cache : bool = true, cache_result : bool = true) -> fetch_response:
	var cache_key : StringName = _create_cache_key(target, prod)
	print("fetch info cache key: ", cache_key)
	if get_from_cache and info == info_types.LATEST_VERSION and cache_key in latest_version_cache.keys():
		print("fetch info got stuff from cache")
		return latest_version_cache[cache_key]
	if connection_statuses[target] != connection_status.CONNECTED or clients[target].get_status() != HTTPClient.Status.STATUS_CONNECTED:
		print("not connected when trying to fetch info")
		return fetch_response.new()
	print("got past cache and connection check stages; fetching info")
	if not is_available_in_api(prod, target):
		print("you cannae get that from there pal")
		return fetch_response.new()
	current_task = task.FETCHING
	var client : HTTPClient = clients[target]
	var continue_attempt : bool = true
	var status : fetch_status = fetch_status.FAILED
	var fetch_resp : fetch_response = fetch_response.new(status, info, "", {"platform": platforms.find_key(exec_type)})
	var response : String = ""
	var attempt_start_time : float = Time.get_unix_time_from_system()
	match target:
		api.GITHUB:
			print("/repos/NatZombieGames/" + github_product_to_github_name[prod] + "/releases/latest")
			print('{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}')
			match info:
				info_types.LATEST_VERSION, info_types.EXECUTABLE_URL:
					client.request(
						HTTPClient.METHOD_GET, 
						"/repos/NatZombieGames/" + github_product_to_github_name[prod] + "/releases/latest", 
						["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"], 
						'{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}'
						)
		api.ITCH:
			var key_validation : key_validation_response = validate_key(api.ITCH)
			match key_validation.response:
				key_validation_responses.VALID:
					pass
				key_validation_responses.INVALID:
					get_node("/root/Main").get_confirmation("Your Itch.io key has been found to be invalid and therefor you are unable to use Itch.io services, please check your key is valid and try again.\n\nError details: " + key_validation_response_details.find_key(key_validation.details).capitalize(), ["OK"])
					current_task = task.INACTIVE
					return fetch_response.new()
				key_validation_responses.UNKNOWN:
					get_node("/root/Main").get_confirmation("Your Itch.io key was unable to be checked, as such until it is validated no Itch.io services can be used.", ["OK"])
					current_task = task.INACTIVE
					return fetch_response.new()
			print("/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/game/" + itch_product_to_itch_id[prod] + "/uploads")
			match info:
				info_types.LATEST_VERSION, info_types.EXECUTABLE_URL:
					client.request(
						HTTPClient.METHOD_GET, 
						"/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/game/" + itch_product_to_itch_id[prod] + "/uploads", 
						["accept:json"], 
						""
						)
	while continue_attempt:
		client.poll()
		match client.get_status():
			HTTPClient.Status.STATUS_BODY:
				print("fetch info resp code: ", client.get_response_code())
				match client.get_response_code():
					HTTPClient.ResponseCode.RESPONSE_OK:
						mutexes[mutex_type.TASK].lock()
						current_task = task.DOWNLOADING
						mutexes[mutex_type.TASK].unlock()
						response = ""
						download_progress = 0
						var length : int = maxi(1, client.get_response_body_length())
						var response_json : Dictionary[String, Variant]
						print("info length: ", length)
						while len(response) < length:
							response += client.read_response_body_chunk().get_string_from_utf8()
							download_progress = len(response)
							#print("! Info Download percentage: ", (download_progress / length) * 100, "%")
						print("info res length at end: ", len(response))
						#print("\n", response, "\n\n", JSON.parse_string(response), "\n\n", JSON.parse_string(response)["assets"][0]["browser_download_url"], "\n")
						response_json.assign(JSON.parse_string(response))
						#print("resp json: ", response_json)
						fetch_resp.data["size"] = length
						match target:
							api.GITHUB:
								fetch_resp.data["version"] = response_json["name"]
								match info:
									info_types.LATEST_VERSION:
										response = response_json["name"]
										status = fetch_status.RETRIEVED
									info_types.EXECUTABLE_URL:
										status = fetch_status.FAILED
										for asset : Dictionary in response_json["assets"]:
											if [false, asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe")][exec_type]:
												response = asset["browser_download_url"]
												status = fetch_status.RETRIEVED
							api.ITCH:
								fetch_resp.data["version"] = response_json["uploads"][0]["display_name"]
								fetch_resp.data["version"] = fetch_resp.data["version"].right(len(fetch_resp.data["version"]) - 1 - fetch_resp.data["version"].to_lower().rfind("v"))
								match info:
									info_types.LATEST_VERSION:
										response = fetch_resp.data["version"]
										status = fetch_status.RETRIEVED
									info_types.EXECUTABLE_URL:
										status = fetch_status.FAILED
										for upload : Dictionary in response_json["uploads"]:
											if [false, upload["p_windows"], upload["p_linux"]][exec_type] == true:
												upload["id"] = int(upload["id"])
												response = "https://itch.io/api/1/" + str(UserManager.settings[&"ItchAPIKey"]) + "/upload/" + str(upload["id"]) + "/download"
												fetch_resp.data["upload_id"] = upload["id"]
												status = fetch_status.RETRIEVED
						#print("\n", response, "\n")
					HTTPClient.ResponseCode.RESPONSE_TOO_MANY_REQUESTS:
						print("You have been rate limited lol")
						get_node("/root/Main").get_confirmation("You have been rate-limited from " + api_to_api_name[target] + ".\nYou will need to wait before you can use their service again, the time can vary so please check back later and try again.", ["OK"])
					_:
						print("unhandled response code during fetch info :(")
				continue_attempt = false
			HTTPClient.Status.STATUS_REQUESTING:
				continue_attempt = (int(Time.get_unix_time_from_system() - attempt_start_time) < connection_timeout_threshold)
				if not continue_attempt:
					status = fetch_status.TIMEOUT
			_:
				print("unhandled exception occured during fetch info, status: ", client.get_status())
				continue_attempt = false
	current_task = task.INACTIVE
	fetch_resp.response = response
	fetch_resp.status = status
	if cache_result and status == fetch_status.RETRIEVED and info in [info_types.LATEST_VERSION]:
		match info:
			info_types.LATEST_VERSION:
				latest_version_cache[cache_key] = fetch_resp
	attempt_connection(target)
	return fetch_resp

func validate_key(key_api : api) -> key_validation_response:
	if valid_api_key_cache.get(key_api, false) == true:
		return key_validation_response.new(key_validation_responses.VALID, key_validation_response_details.NONE)
	if not api_requires_key[key_api]:
		return key_validation_response.new(key_validation_responses.VALID, key_validation_response_details.UNNECESSARY)
	if len(UserManager.settings[UserManager.api_to_api_key_setting_name[key_api]]) < 1:
		return key_validation_response.new(key_validation_responses.INVALID, key_validation_response_details.UNREADABLE_KEY)
	var client : HTTPClient = clients[key_api]
	if client.get_status() != HTTPClient.Status.STATUS_CONNECTED:
		var attemps : int = 0
		while attemps < 2:
			attempt_connection(key_api)
			if client.get_status() == HTTPClient.Status.STATUS_CONNECTED:
				attemps = 2
			attemps += 1
	if client.get_status() != HTTPClient.Status.STATUS_CONNECTED:
		return key_validation_response.new(key_validation_responses.INVALID, key_validation_response_details.FAILED_TO_CONNECT)
	match key_api:
		api.ITCH:
			client.request(
				HTTPClient.METHOD_GET,
				"/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/credentials/info",
				["accept:json"]
				)
	var starting_time : float = Time.get_unix_time_from_system()
	var continue_attempt : bool = true
	while continue_attempt:
		client.poll()
		match client.get_status():
			HTTPClient.Status.STATUS_BODY:
				match client.get_response_code():
					HTTPClient.ResponseCode.RESPONSE_OK:
						var response : String = ""
						var length : int = maxi(1, client.get_response_body_length())
						print(client.get_response_headers())
						print("resp code: ", client.get_response_code())
						print("status: ", client.get_status())
						print("length: ", length)
						while len(response) < length:
							response += client.read_response_body_chunk().get_string_from_utf8()
						match key_api:
							api.ITCH:
								if JSON.parse_string(response)["type"] == "key":
									valid_api_key_cache[api.ITCH] = true
									return key_validation_response.new(key_validation_responses.VALID, key_validation_response_details.NONE)
						continue_attempt = false
					HTTPClient.ResponseCode.RESPONSE_TOO_MANY_REQUESTS:
						print("You have been rate limited lol")
						get_node("/root/Main").get_confirmation("You have been rate-limited from " + api_to_api_name[key_api] + ".\nYou will need to wait before you can use their service again, the time can vary so please check back later and try again.", ["OK"])
						continue_attempt = false
					_:
						print("uh ohhh, no good: ", client.get_response_code())
						continue_attempt = false
			HTTPClient.Status.STATUS_REQUESTING:
				continue_attempt = (Time.get_unix_time_from_system() - starting_time) < connection_timeout_threshold
			_:
				print("uh ow, ewwor: ", client.get_status())
				continue_attempt = false
	return key_validation_response.new(key_validation_responses.INVALID, key_validation_response_details.FAILED_TO_CONNECT)

func download_executable(url : String, prod : product, fetch_data : Dictionary[String, Variant], target : api) -> PackedByteArray:
	var thread : Thread = Thread.new()
	thread.start(Callable(self, "_threaded_download_executable").bindv([url, prod, target]))
	var start_time : float = Time.get_unix_time_from_system()
	var api_name : String = api.find_key(target)
	while thread.is_alive():
		await get_tree().process_frame
		mutexes[mutex_type.DOWNLOAD_SIZE].lock()
		mutexes[mutex_type.DOWNLOAD_PROGRESS].lock()
		main.update_download_visuals(product_to_name[prod], fetch_data["version"], fetch_data["platform"], api_name, download_size, Time.get_unix_time_from_system() - start_time, download_progress)
		mutexes[mutex_type.DOWNLOAD_SIZE].unlock()
		mutexes[mutex_type.DOWNLOAD_PROGRESS].unlock()
	return thread.wait_to_finish()

func _threaded_download_executable(url : String, prod : product, target : api) -> PackedByteArray:
	var result : PackedByteArray = []
	var client : HTTPClient = HTTPClient.new()
	var continue_attempt : bool = true
	var attempt_start_time : float = Time.get_unix_time_from_system()
	print("url: ", url, "\nhost: ", url.right(-8).get_slice("/", 0) + "\nprod: " + product.find_key(prod) + "\napi: " + api.find_key(target))
	client.read_chunk_size = maxi(UserManager.settings[&"DownloadMaximumPacketSize"], 1)
	client.connect_to_host("https://" + url.right(-8).get_slice("/", 0))
	mutexes[mutex_type.TASK].lock()
	current_task = task.CONNECTING
	mutexes[mutex_type.TASK].unlock()
	mutexes[mutex_type.DOWNLOAD_PROGRESS].lock()
	download_progress = 0
	mutexes[mutex_type.DOWNLOAD_PROGRESS].unlock()
	print("here 1")
	while continue_attempt:
		client.poll()
		match client.get_status():
			HTTPClient.Status.STATUS_CONNECTED:
				continue_attempt = false
				print("here 2")
			HTTPClient.Status.STATUS_RESOLVING, HTTPClient.Status.STATUS_CONNECTING:
				continue_attempt = (int(Time.get_unix_time_from_system() - attempt_start_time)) < connection_timeout_threshold
			_:
				print("!!! Threaded Download Failing status: ", client.get_status())
				continue_attempt = false
	if client.get_status() != HTTPClient.Status.STATUS_CONNECTED:
		print("unable to connect during exec download :(")
		return result
	print("here 3")
	var request_target : String = url.right(len("https://" + url.right(-8).get_slice("/", 0)) * -1)
	print(request_target)
	match target:
		api.GITHUB:
			client.request(
				HTTPClient.METHOD_GET, 
				request_target, 
				["X-GitHub-Api-Version:2022-11-28"], 
				'{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}'
				)
		api.ITCH:
			client.request(
				HTTPClient.METHOD_GET, 
				request_target, 
				["accept:json"], 
				""
				)
	mutexes[mutex_type.TASK].lock()
	current_task = task.DOWNLOADING
	mutexes[mutex_type.TASK].unlock()
	continue_attempt = true
	while continue_attempt:
		client.poll()
		match client.get_status():
			HTTPClient.Status.STATUS_BODY:
				match client.get_response_code():
					HTTPClient.ResponseCode.RESPONSE_OK:
						var length : int = maxi(1, client.get_response_body_length())
						var chunk : PackedByteArray
						print("\n\n\nDOWNLOADING EXEC!!!!! " + url + "\n\n\n")
						print(client.get_response_headers())
						print(client.get_response_code())
						print("length: ", length)
						mutexes[mutex_type.DOWNLOAD_SIZE].lock()
						download_size = length
						mutexes[mutex_type.DOWNLOAD_SIZE].unlock()
						while len(result) < length:
							chunk = client.read_response_body_chunk()
							result.append_array(chunk)
							mutexes[mutex_type.DOWNLOAD_PROGRESS].lock()
							download_progress = len(result)
							mutexes[mutex_type.DOWNLOAD_PROGRESS].unlock()
							#print("Downloaded Chunk len: ", len(chunk))
							#print("! Download percentage: ", download_percentage * 100, "%")
						print("done?!?!?!??!?!?!?! please?!?!??!")
						print("res length at end: ", len(chunk))
						#print("\n", chunk, "\n")
						if target == api.ITCH and length < 10_000:
							result = _threaded_download_executable(JSON.parse_string(result.get_string_from_utf8())["url"], prod, target)
						continue_attempt = false
					HTTPClient.ResponseCode.RESPONSE_FOUND:
						print("\n\n-")
						var resp_heads : Array = client.get_response_headers()
						resp_heads.map(func(item : String) -> String: print(resp_heads.find(item), ": ", item, "\n-"); return item)
						print(len(resp_heads))
						print(resp_heads)
						print("\nredirect :(")
						match target:
							api.GITHUB:
								result = _threaded_download_executable(resp_heads[4].right(-10), prod, target)
						continue_attempt = false
					HTTPClient.ResponseCode.RESPONSE_TOO_MANY_REQUESTS:
						print("You have been rate limited lol")
						get_node("/root/Main").get_confirmation("You have been rate-limited from " + api_to_api_name[target] + ".\nYou will need to wait before you can use their service again, the time can vary so please check back later and try again.", ["OK"])
						continue_attempt = false
					_:
						print("uh oh i got here :(, ", client.get_response_code())
						continue_attempt = false
			HTTPClient.Status.STATUS_REQUESTING:
				continue_attempt = (int(Time.get_unix_time_from_system() - attempt_start_time) < connection_timeout_threshold)
			_:
				print("\n\nSTATUS!!!!!!!: ", client.get_status())
				print(client.get_response_headers())
				print(client.get_response_code())
				continue_attempt = false
	print("i got here with my response during exec return")
	mutexes[mutex_type.TASK].lock()
	current_task = task.INACTIVE
	mutexes[mutex_type.TASK].unlock()
	return result
