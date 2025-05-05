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
var current_task : task = task.INACTIVE
var download_percentage : float = 0.0
var download_size : int = 0
var mutexes : Dictionary[mutex_type, Mutex] = {
	mutex_type.TASK: Mutex.new(), 
	mutex_type.DOWNLOAD_PERCENTAGE: Mutex.new(), 
	mutex_type.DOWNLOAD_SIZE: Mutex.new(), 
}
const api_to_api_url : Dictionary[api, String] = {
	api.GITHUB: "https://api.github.com", 
	api.ITCH: "https://itch.io"
}
## In order of API enum.
const product_to_api_availability : Dictionary[product, Array] = {
	product.NPS: [true, false], 
	product.NMP: [true, true], 
	product.NDP: [true, false], 
	product.MINING_IDLE: [false, true], 
	product.UNKNOWN: [false, false], 
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
	product.NPS: [product_category.SOFTWARE], 
	product.NMP: [product_category.SOFTWARE], 
	product.NDP: [product_category.SOFTWARE], 
	product.MINING_IDLE: [product_category.GAME], 
}
const product_to_name : Dictionary[product, String] = {
	product.NPS: "Nat Password Software", 
	product.NMP: "Nat Music Programme", 
	product.NDP: "Nat Documenter Programme", 
	product.MINING_IDLE: "Mining Idle", 
}
const connection_timeout_threshold : int = 15
enum api {GITHUB, ITCH}
enum product {NPS, NMP, NDP, MINING_IDLE, UNKNOWN}
enum product_category {SOFTWARE, GAME}
enum mutex_type {TASK, DOWNLOAD_PERCENTAGE, DOWNLOAD_SIZE}
enum task {INACTIVE, CONNECTING, FETCHING, DOWNLOADING}
enum connection_status {CONNECTED, FAILED, TIMEOUT, CLOSED, NOT_ATTEMPTED}
enum fetch_status {RETRIEVED, FAILED, TIMEOUT}
enum info_types {UNKNOWN, LATEST_VERSION, EXECUTABLE_URL}
enum executable_types {WINDOWS, LINUX}
class fetch_response:
	func _init(stat : fetch_status = fetch_status.FAILED, typ : info_types = info_types.UNKNOWN, resp : String = "", new_data : Dictionary[String, Variant] = {}) -> void:
		status = stat
		type = typ
		response = resp
		data = new_data
		return
	var status : fetch_status = fetch_status.FAILED
	var type : info_types = info_types.UNKNOWN
	var data : Dictionary[String, Variant] = {}
	var response : String = ""
	func _get_details() -> void:
		print("\n---\n-Status: " + fetch_status.find_key(status) + "\n-Type: " + info_types.find_key(type) + "\n-Data: " + str(data) + "\n-Response:\n-- " + response + "\n---\n")
		return

func _get_api_details(target : api) -> void:
	print("\n---\n-API: " + api.find_key(target) + "\n-Status: " + connection_status.find_key(connection_statuses[target]) + "\n-URL:\n-- " + api_to_api_url[target] + "\n---\n")
	return

func clean_up_clients() -> void:
	for target : api in api.values():
		close_connection(target)
	return

func close_connection(target : api) -> void:
	clients[target].close()
	connection_statuses[target] = connection_status.CLOSED
	return

func is_available_in_api(prod : product, app : api) -> bool:
	return product_to_api_availability[prod][app]

func attempt_connection(target : api) -> connection_status:
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
				continue_attempt = false
				status = connection_status.CONNECTED
			HTTPClient.Status.STATUS_RESOLVING, HTTPClient.Status.STATUS_CONNECTING:
				continue_attempt = (int(Time.get_unix_time_from_system() - attempt_start_time)) < connection_timeout_threshold
				if not continue_attempt:
					status = connection_status.TIMEOUT
			_:
				print("!!! Connection Attempt Failing status: ", client.get_status())
				continue_attempt = false
				status = connection_status.FAILED
	connection_statuses[target] = status
	_get_api_details(target)
	current_task = task.INACTIVE
	return status

func fetch_info(target : api, prod : product, info : info_types, exec_type : executable_types = executable_types.WINDOWS) -> fetch_response:
	if not connection_statuses[target] == connection_status.CONNECTED or clients[target].get_status() != HTTPClient.Status.STATUS_CONNECTED:
		return fetch_response.new()
	current_task = task.FETCHING
	var client : HTTPClient = clients[target]
	var continue_attempt : bool = true
	var attempt_start_time : float = Time.get_unix_time_from_system()
	var status : fetch_status = fetch_status.FAILED
	var fetch_resp : fetch_response = fetch_response.new(status, info, "", {"platform": executable_types.find_key(exec_type)})
	var response : String = ""
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
			print("/api/1/" + UserManager.user_settings[UserManager.setting_key.ItchAPIKey] + "/game/" + itch_product_to_itch_id[prod] + "/uploads")
			match info:
				info_types.EXECUTABLE_URL:
					if not is_available_in_api(prod, target):
						return fetch_response.new()
					client.request(
						HTTPClient.METHOD_GET, 
						"/api/1/" + UserManager.user_settings[UserManager.setting_key.ItchAPIKey] + "/game/" + itch_product_to_itch_id[prod] + "/uploads", 
						["accept:json"], 
						""
						)
	while continue_attempt:
		client.poll()
		match client.get_status():
			HTTPClient.Status.STATUS_BODY:
				print(client.get_response_code())
				match client.get_response_code():
					HTTPClient.ResponseCode.RESPONSE_OK:
						current_task = task.DOWNLOADING
						response = ""
						download_percentage = 0.0
						var length : int = maxi(1, client.get_response_body_length())
						var response_json : Dictionary[String, Variant]
						print("info length: ", length)
						while len(response) < length:
							response += client.read_response_body_chunk().get_string_from_utf8()
							download_percentage = float(len(response)) / float(length)
							print("! Info Download percentage: ", download_percentage * 100, "%")
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
											if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe")][exec_type]:
												response = asset["browser_download_url"]
												status = fetch_status.RETRIEVED
							api.ITCH:
								fetch_resp.data["version"] = response_json["uploads"][0]["display_name"].replace(response_json["uploads"][0]["filename"] + " ", "")
								match info:
									info_types.LATEST_VERSION:
										response = fetch_resp.data["version"]
										status = fetch_status.RETRIEVED
									info_types.EXECUTABLE_URL:
										status = fetch_status.FAILED
										for upload : Dictionary in response_json["uploads"]:
											if [upload["p_windows"], upload["p_linux"]][exec_type] == true:
												response = "https://itch.io/api/1/" + str(UserManager.user_settings[UserManager.setting_key.ItchAPIKey]) + "/upload/" + str(upload["id"]) + "/download"
												status = fetch_status.RETRIEVED
						#print("\n", response, "\n")
				continue_attempt = false
			HTTPClient.Status.STATUS_REQUESTING:
				continue_attempt = (int(Time.get_unix_time_from_system() - attempt_start_time) < connection_timeout_threshold)
				if not continue_attempt:
					status = fetch_status.TIMEOUT
			_:
				print(client.get_status())
				continue_attempt = false
	current_task = task.INACTIVE
	fetch_resp.response = response
	fetch_resp.status = status
	return fetch_resp

func download_executable(url : String, prod : product, fetch_data : Dictionary[String, Variant], target : api) -> PackedByteArray:
	var thread : Thread = Thread.new()
	thread.start(Callable(self, "_threaded_download_executable").bindv([url, prod, target]))
	var start_time : float = Time.get_unix_time_from_system()
	while thread.is_alive():
		await get_tree().process_frame
		mutexes[mutex_type.DOWNLOAD_SIZE].lock()
		main.update_download_visuals(product.find_key(prod), fetch_data["version"], fetch_data["platform"], download_size, Time.get_unix_time_from_system() - start_time, download_percentage)
		mutexes[mutex_type.DOWNLOAD_SIZE].unlock()
	return thread.wait_to_finish()

func _threaded_download_executable(url : String, prod : product, target : api) -> PackedByteArray:
	var result : PackedByteArray = []
	var client : HTTPClient = HTTPClient.new()
	var continue_attempt : bool = true
	var attempt_start_time : float = Time.get_unix_time_from_system()
	print("url: ", url, "\nhost: ", "https://" + url.right(-8).get_slice("/", 0))
	client.connect_to_host("https://" + url.right(-8).get_slice("/", 0))
	mutexes[mutex_type.TASK].lock()
	current_task = task.CONNECTING
	mutexes[mutex_type.TASK].unlock()
	mutexes[mutex_type.DOWNLOAD_PERCENTAGE].lock()
	download_percentage = 0.0
	mutexes[mutex_type.DOWNLOAD_PERCENTAGE].unlock()
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
				print("!!! Failing status: ", client.get_status())
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
						print("length: ", length)
						mutexes[mutex_type.DOWNLOAD_SIZE].lock()
						download_size = length
						mutexes[mutex_type.DOWNLOAD_SIZE].unlock()
						while len(result) < length:
							chunk = client.read_response_body_chunk()
							result.append_array(chunk)
							mutexes[mutex_type.DOWNLOAD_PERCENTAGE].lock()
							download_percentage = float(len(result)) / float(length)
							mutexes[mutex_type.DOWNLOAD_PERCENTAGE].unlock()
							#print("Downloaded Chunk len: ", len(chunk))
							#print("! Download percentage: ", download_percentage * 100, "%")
						print("done?!?!?!??!?!?!?! please?!?!??!")
						print("res length at end: ", len(chunk))
						#print("\n", chunk, "\n")
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
