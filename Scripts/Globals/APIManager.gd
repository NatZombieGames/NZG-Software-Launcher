extends Node
##The manager of all the API and networking related requests

##/root/Main
var main : Control
##Cache of the valid [constant info_types.LATEST_VERSION] response for each [enum product] using a cache key from [method _create_cache_key]
var latest_version_cache : Dictionary[StringName, response] = {}
##Cache of the valid [constant info_types.DOWNLOAD_URL] response for each [enum product] using a cache key from [method _create_cache_key]
var download_url_cache : Dictionary[StringName, response] = {}
##Cache of the valid [constant info_types.EXECUTABLE_SIZE] response for each [enum product] using a cache key from [method _create_cache_key]
var executable_size_cache : Dictionary[StringName, response] = {}
##Cache of the valid [constant info_types.DESCRIPTION] response for each [enum product] using a cache key from [method _create_cache_key]
var description_cache : Dictionary[StringName, response] = {}
##Cache of the valid [constant info_types.READ_ME] response for each [enum product] using a cache key from [method _create_cache_key]
var read_me_cache : Dictionary[StringName, response] = {}
##Caches if the api key for the given [enum api] is valid[br][br](Clears when key is changed)
var valid_api_key_cache : Dictionary[api, bool] = {}
##Current download progress as the amount of content currently downloaded, used to be compared against [member download_size]
var download_progress : int = 0
##Current download size, used to be compared against [member download_size]
var download_size : int = 0
##The size of the last packet received during a download
var last_packet_size : int = 0
##The latest host used during a request
var request_host : String = ""
##A [Mutex] for each [enum mutex_type]
var mutexes : Dictionary[mutex_type, Mutex] = {
	mutex_type.DOWNLOAD_PROGRESS: Mutex.new(), 
	mutex_type.DOWNLOAD_SIZE: Mutex.new(), 
	mutex_type.LAST_PACKET_SIZE: Mutex.new(), 
	mutex_type.REQUEST_HOST: Mutex.new(), 
}
##The url used to connect to each [enum api]
const api_to_api_url : Dictionary[api, String] = {
	api.GITHUB: "https://api.github.com", 
	api.ITCH: "https://itch.io"
}
##The displayable name for each [enum api]
const api_to_api_name : Dictionary[api, String] = {
	api.GITHUB: "GitHub", 
	api.ITCH: "Itch.io", 
}
##If the given [enum api] needs a api key[br][br]Also see [member valid_api_key_cache]
const api_requires_key : Dictionary[api, bool] = {
	api.GITHUB: false, 
	api.ITCH: true, 
}
## An [Array] of [bool] to say if a [enum product] is available for an [enum api], in order of the [enum api] enum[br][br]Used by [method get_available_api] and [method is_available_in_api]
const product_to_api_availability : Dictionary[product, Array] = {
	product.NPS: [true, false], 
	product.NMP: [true, true], 
	product.MINING_IDLE: [false, true], 
	product.UNKNOWN: [false, false], 
}
## A [PackedStringArray] of urls for the given [enum product] for each [enum api] in the order of the [enum api] enum
const product_to_source : Dictionary[product, Array] = {
	product.NPS: ["https://github.com/NatZombieGames/Nat-Password-Software", ""], 
	product.NMP: ["https://github.com/NatZombieGames/Nat-Music-Programme", "https://natzombiegames.itch.io/nat-music-programme"], 
	product.MINING_IDLE: ["", "https://natzombiegames.itch.io/mining-idle"], 
	product.UNKNOWN: ["", ""], 
}
##Github name of each [enum product] that is available from [constant api.GITHUB]
const github_product_to_github_name : Dictionary[product, String] = {
	product.NPS: "Nat-Password-Software", 
	product.NMP: "Nat-Music-Programme", 
}
##Itch ID for each [enum product] that is available from [constant api.ITCH]
const itch_product_to_itch_id : Dictionary[product, String] = {
	product.NMP: "3398181", 
	product.MINING_IDLE: "3095012", 
}
##Each [enum product]'s categories ([enum product_category]) in an [Array]
const product_to_product_categories : Dictionary[product, Array] = {
	product.NPS: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.NMP: [product_category.SOFTWARE, product_category.OPEN_SOURCE], 
	product.MINING_IDLE: [product_category.GAMES], 
}
##Each [enum product]'s name
const product_to_name : Dictionary[product, String] = {
	product.NPS: "Nat Password Software", 
	product.NMP: "Nat Music Programme", 
	product.MINING_IDLE: "Mining Idle", 
}
##The path ammendment to add when grabbing the specified type of [enum info_types] from [constant api.GITHUB]
const github_info_type_to_url_path_ammendment : Dictionary[info_types, String] = {
	info_types.LATEST_VERSION: "/releases/latest", 
	info_types.DOWNLOAD_URL: "/releases/latest", 
	info_types.EXECUTABLE_SIZE: "/releases/latest", 
	info_types.DESCRIPTION: "", 
	info_types.READ_ME: "/contents/README.md", 
}
##The path ammendment to add when grabbing the specified type of [enum info_types] from [constant api.ITCH]
const itch_info_type_to_url_path_ammendment : Dictionary[info_types, String] = {
	info_types.LATEST_VERSION: "/uploads", 
	info_types.DOWNLOAD_URL: "/uploads", 
	info_types.EXECUTABLE_SIZE: "/uploads", 
	info_types.DESCRIPTION: "", 
	info_types.READ_ME: ">this cant / shouldnt be used as only github has readme files<", 
	}
##The types of info covered by each of the [enum batch_types]
const batch_type_to_info_list : Dictionary[batch_types, Array] = {
	batch_types.GENERAL_INFO: [
		info_types.LATEST_VERSION, 
		info_types.DOWNLOAD_URL, 
		info_types.EXECUTABLE_SIZE
		], 
	}
##Connection length threshold before timing out
const connection_timeout_threshold : int = 5
##Connection maximum retries before exiting
const connection_max_retries : int = 2
##Connection maximum redirects before exiting
const connection_max_redirects : int = 5
##The available api's
enum api {GITHUB, ITCH, UNKNOWN}
##All the products
enum product {NPS, NMP, MINING_IDLE, UNKNOWN}
##All the product categories
enum product_category {SOFTWARE, GAMES, OPEN_SOURCE}
##All the mutex types
enum mutex_type {
	DOWNLOAD_PROGRESS, ##Also see [member download_progress]
	DOWNLOAD_SIZE, ##Also see [member download_size]
	LAST_PACKET_SIZE, ##Also see [member last_packet_size]
	REQUEST_HOST, ##Also see [member request_host]
	}
##All the [response] return types
enum return_types {STR, BYT}
##All the info types, used by [method fetch_info] to retrieve individual types of info[br][br]Also see [enum batch_types]
enum info_types {LATEST_VERSION, DOWNLOAD_URL, EXECUTABLE_SIZE, DESCRIPTION, READ_ME}
##All the batch types, used by [method fetch_batch] to retrieve multiple pieces of info from the same end-point without making multiple requests[br][br]Also see [enum info_types]
enum batch_types {GENERAL_INFO}
##All the user and executable platforms
enum platforms {WINDOWS, LINUX, UNKNOWN}
##All the [response] failure types
enum failures {
	UNKNOWN, ##Unknown error occured
	NONE, ##No error occured; should only be used when [member response.success] is [code]true[/code]
	CONNECTION_FAILED, ##The connection failed to connect
	TIMEOUT, ##The connection timedout by taking longer to connect then the [constant connection_timeout_threshold] allowed
	REDIRECT, ##The response was a redirect, so check the [member response.details] for info about where to request next
	RATE_LIMITED, ##You were rate-limited by the service
	UNHANDLED_STATUS_OR_CODE_RETURNED, ##An unhandled [enum HTTPClient.Status] or [enum HTTPClient.ResponseCode] was returned 
	INVALID_HOST, ##The host you attempted to connect to was invalid
	INVALID_KEY, ##The api key you wanted to check was invalid
	UNREADABLE_KEY, ##The api key you wanted to check was unreadable (0-Length string)
	NO_AVAILABLE_API, ##No available api was found for the given product; this shouldn't happen
	INVALID_SELECTION, ##An invalid / unknown selection was given
	}
##The return type of most of the complex functions by the [APIManager], used to check details about the returned data such as error codes and returned values
class response:
	##Wether the request was succesfull, this can be used to do simple [code]if response.success:[/code] checks
	var success : bool
	##The failure this response is reporting, can be used to help report or fix the issue, if this failure is [constant failures.NONE] then [member success] should be [code]true[/code]
	var failure : failures
	##The details about this response; such as returned codes or extra information
	var details : Dictionary[String, Variant]
	##The return type of this response, also see [member returned_str] and [member returned_byt]
	var return_type : return_types
	##The returned [String] by this response, also see [member return_type] and [member returned_byt]
	var returned_str : String
	##The returned bytes ([PackedByteArray]) by this response, also see [member return_type] and [member returned_str]
	var returned_byt : PackedByteArray
	func _init(nsuccess : bool = false, nfailure : failures = failures.UNKNOWN, ndetails : Dictionary[String, Variant] = {}, nreturn_type : return_types = return_types.STR, nreturned_str : String = "", nreturned_byt : PackedByteArray = []) -> void:
		success = nsuccess
		failure = nfailure
		details = ndetails
		return_type = nreturn_type
		returned_str = nreturned_str
		returned_byt = nreturned_byt
		return
	##Prints the information about this response to the console for debugging, prints all the values held by this response
	func _get_details() -> void:
		print("---\n- Success: " + str(success).capitalize() + "\n- Failure: " + str(failures.find_key(failure)).capitalize() + "\n- Details:\n-- " + str(details) + "\n- Returned Type: " + return_types.find_key(return_type) + "\n- Returned Str: " + returned_str + "\n- Returned Bytes?: " + str(len(returned_byt) > 0) + "\n---")
		return

##Returns a cache key made of the given [param target] and [param prod]
func _create_cache_key(target : api, prod : product) -> StringName:
	return StringName(String.num_uint64(target, 2).lpad(8, "0") + "|" + String.num_uint64(prod, 2).lpad(8, "0"))

##Returns the first [enum api] the given [param prod] is available in, or [constant api.UNKNOWN] if non if available
func get_available_api(prod : product) -> api:
	if true in product_to_api_availability[prod]:
		@warning_ignore("int_as_enum_without_cast")
		return product_to_api_availability[prod].find(true)
	_report_failure("APIManager Failure", "Given product has no available api", {"product": prod, "product_availability": product_to_api_availability[prod]})
	return api.UNKNOWN

##Returns if the given [param prod] is available in the given [param target]
func is_available_in_api(prod : product, target : api) -> bool:
	return product_to_api_availability.get(prod, [false, false])[target]

##Fetches the given [param info] about the given [param prod], returns a [response][br][br]Also see [enum info_types] and [method fetch_batch]
func fetch_info(prod : product, info : info_types) -> response:
	if prod == product.UNKNOWN:
		_report_failure("Fetch Failure", "When attempting to fetch info of type: '" + info_types.find_key(info) + "' about a product the product was unknown", {"product": prod, "info": info})
		return response.new(false, failures.INVALID_SELECTION)
	var target : api = get_available_api(prod)
	if target == api.UNKNOWN:
		_report_failure("Fetch Failure", "When attempting to fetch info of type: '" + info_types.find_key(info) + "' about the product: '" + product.find_key(prod) + "' no available API was found", {"product": prod, "info": info})
		return response.new(false, failures.NO_AVAILABLE_API)
	if info == info_types.READ_ME and target != api.GITHUB:
		_report_failure("Fetch Warning", "When fetching info of type READ_ME the product was not being gotten from GitHub, returned succes with an empty string.", {"product": product, "info": info, "api": target})
		return response.new(true, failures.NONE)
	var cache_key : StringName = _create_cache_key(target, prod)
	var cache_response : response
	var cache : Dictionary[StringName, response] = self.get(StringName(str(info_types.find_key(info)).to_snake_case() + "_cache"))
	if cache_key in cache.keys() and cache[cache_key].success:
		cache_response = cache[cache_key]
	if cache_response:
		cache_response.details["cached"] = true
		return cache_response
	var fetch_response : response = response.new()
	var details : Dictionary[String, Variant] = {
		"request_response": null, 
		"key_response": null, 
		"version": "0.0.0", 
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
			url = "/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/game/" + itch_product_to_itch_id[prod] + itch_info_type_to_url_path_ammendment[info]
			headers = ["accept:json"]
			body = ""
		api.GITHUB:
			url = "/repos/NatZombieGames/" + github_product_to_github_name[prod] + github_info_type_to_url_path_ammendment[info]
			headers = ["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"]
			body = '{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}'
	var request_response : response = _request_url(url, headers, body, api_to_api_url[target])
	if not request_response.success:
		print("Fetch info failed.")
		_report_failure("Fetch Failure", "When attempting to fetch the info: '" + info_types.find_key(info) + "' an error occured when fetching from the url", {"product": prod, "info": info, "api": target, "failure": request_response.failure, "details": request_response.details, "url": url, "headers": headers, "body": body, "host": api_to_api_url[target]})
		return response.new(false, request_response.failure, details)
	details["request_response"] = request_response
	var parsed : PackedStringArray = parse_fetched_info(target, [info], request_response.returned_str)
	if info != info_types.LATEST_VERSION:
		parsed.append_array(parse_fetched_info(target, [info_types.LATEST_VERSION], request_response.returned_str))
	fetch_response.details["version"] = parsed[[1, 0][int(info == info_types.LATEST_VERSION)]]
	fetch_response.returned_str = parsed[0]
	fetch_response.details = details
	fetch_response.success = true
	fetch_response.failure = failures.NONE
	cache[cache_key] = fetch_response
	return fetch_response

##Fetches the given [param batch] about the given [param prod], returns a [Array][lb][response][rb][br][br]Also see [enum batch_types] and [method fetch_info]
func fetch_batch(prod : product, batch : batch_types) -> Array[response]:
	#breakpoint
	if prod == product.UNKNOWN:
		_report_failure("Batch Failure", "When attempting to fetch batch of type: '" + batch_types.find_key(batch) + "' about a product the product was unknown", {"product": prod, "batch": batch})
		return [response.new(false, failures.INVALID_SELECTION)]
	var target : api = get_available_api(prod)
	if target == api.UNKNOWN:
		_report_failure("Batch Failure", "When attempting to fetch batch of type: '" + batch_types.find_key(batch) + "' about the product: '" + product.find_key(prod) + "' no available API was found", {"product": prod, "batch": batch})
		return [response.new(false, failures.NO_AVAILABLE_API)]
	var cache_key : StringName = _create_cache_key(target, prod)
	var cache_response : response
	var cache : Dictionary[StringName, response]
	var info : info_types
	var responses : Array[response]
	responses.resize(len(batch_type_to_info_list[batch]))
	responses.fill(null)
	for i : int in range(0, len(batch_type_to_info_list[batch])):
		@warning_ignore("int_as_enum_without_cast")
		responses[i] = response.new()
		info = batch_type_to_info_list[batch][i]
		cache = self.get(StringName(str(info_types.find_key(info)).to_snake_case() + "_cache"))
		if cache_key in cache.keys() and cache[cache_key].success:
			cache_response = cache[cache_key]
			cache_response.details["cached"] = true
			responses[i] = cache_response
			print("cache hit for " + info_types.find_key(info) + " during batch fetch of type " + batch_types.find_key(batch) + " for product " + product.find_key(prod))
	if not (false in responses.map(func(item : response) -> bool: return item.success)):
		print("all caches hit during batch fetch of type " + batch_types.find_key(batch) + " for product " + product.find_key(prod))
		return responses
	var details : Dictionary[String, Variant]
	var url : String
	var headers : PackedStringArray
	var body : String
	match target:
		api.ITCH:
			var key_response : response = validate_key(api.ITCH)
			details["key_response"] = key_response
			if not key_response.success:
				if key_response.failure == failures.INVALID_KEY:
					_report_failure("Batch Failure", "Tried to access an Itch.io product and the Itch.io key was found to be invalid", {"product": prod, "batch": batch, "api": target, "failure": key_response.failure, "details": key_response.details, "returned_str": key_response.returned_str, "key": UserManager.settings[&"ItchAPIKey"]})
				else:
					_report_failure("Batch Failure", "An error occured when attempting to validate an Itch.io key when trying to access an Itch.io product", {"product": prod, "batch": batch, "api": target, "failure": key_response.failure, "details": key_response.details, "returned_str": key_response.returned_str, "key": UserManager.settings[&"ItchAPIKey"]})
				return [response.new(false, key_response.failure, details)]
			url = "/api/1/" + UserManager.settings[&"ItchAPIKey"] + "/game/" + itch_product_to_itch_id[prod] + itch_info_type_to_url_path_ammendment[info]
			headers = ["accept:json"]
			body = ""
		api.GITHUB:
			url = "/repos/NatZombieGames/" + github_product_to_github_name[prod] + github_info_type_to_url_path_ammendment[info]
			headers = ["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"]
			body = '{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}'
	var request_response : response = _request_url(url, headers, body, api_to_api_url[target])
	if not request_response.success:
		print("Batch info failed.")
		_report_failure("Batch Failure", "When attempting to fetch the batch: '" + batch_types.find_key(batch) + "' an error occured when fetching from the url", {"product": prod, "batch": batch, "api": target, "failure": request_response.failure, "details": request_response.details, "url": url, "headers": headers, "body": body, "host": api_to_api_url[target]})
		return [response.new(false, request_response.failure, details)]
	details["request_response"] = request_response
	responses.map(func(item : response) -> response: item.success = true; item.failure = failures.NONE; return item)
	var parsed : PackedStringArray = parse_fetched_info(target, (func() -> Array[info_types]: var arr : Array[info_types]; arr.assign(batch_type_to_info_list[batch]); return arr).call(), request_response.returned_str)
	for i : int in range(0, len(parsed)):
		responses[i].returned_str = parsed[i]
		self.get(StringName(str(info_types.find_key(batch_type_to_info_list[batch][i])).to_snake_case() + "_cache"))[cache_key] = responses[i]
	return responses

##Parses the info retrieved by either [method fetch_batch] or [method fetch_info]
func parse_fetched_info(source : api, desired_info : Array[info_types], info : String) -> PackedStringArray:
	var to_return : PackedStringArray
	to_return.resize(len(desired_info))
	var response_json : Dictionary[String, Variant]
	var version : String = "0.0.0"
	var desired : info_types
	response_json.assign(JSON.parse_string(info))
	for i : int in range(0, len(desired_info)):
		desired = desired_info[i]
		match source:
			api.ITCH:
				version = response_json.get("uploads", [{}])[0].get("display_name", "name V0.0.0")
				version = version.right(len(version) - 1 - version.to_lower().rfind("v"))
				match desired:
					info_types.LATEST_VERSION:
						to_return[i] = version
					info_types.DOWNLOAD_URL:
						for upload : Dictionary in response_json["uploads"]:
							if [upload["p_windows"], upload["p_linux"], true][UserManager.platform] == true:
								upload["id"] = int(upload["id"])
								to_return[i] = "https://itch.io/api/1/" + str(UserManager.settings[&"ItchAPIKey"]) + "/upload/" + str(upload["id"]) + "/download"
					info_types.EXECUTABLE_SIZE:
						for upload : Dictionary in response_json["uploads"]:
							if [upload["p_windows"], upload["p_linux"], true][UserManager.platform] == true:
								to_return[i] = str(upload["size"])
					info_types.DESCRIPTION:
						to_return[i] = response_json["game"]["short_text"]
					info_types.READ_ME:
						to_return[i] = ""
			api.GITHUB:
				version = response_json.get("tag_name", "0.0.0")
				match desired:
					info_types.LATEST_VERSION:
						to_return[i] = version
					info_types.DOWNLOAD_URL:
						for asset : Dictionary in response_json["assets"]:
							if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe"), true][UserManager.platform]:
								to_return[i] = asset["browser_download_url"]
					info_types.EXECUTABLE_SIZE:
						for asset : Dictionary in response_json["assets"]:
							if [asset["name"].ends_with(".exe"), not asset["name"].ends_with(".exe"), true][UserManager.platform]:
								to_return[i] = str(asset["size"])
					info_types.DESCRIPTION:
						to_return[i] = response_json["description"]
					info_types.READ_ME:
						to_return[i] = Marshalls.base64_to_utf8(response_json["content"].replace("\n", ""))
	return to_return

##Fetches the asset from the given [param asset_path] from the given [param prod]'s GitHub repo, returning a [response] with a [param return_type] which defaults to [constant return_types.BYT]
func fetch_github_asset(prod : product, asset_path : String, return_type : return_types = return_types.BYT) -> response:
	if prod == product.UNKNOWN:
		_report_failure("Fetch Asset Failure", "When attempting to fetch a github asset the provided product was invalid", {"product": prod, "asset_path": asset_path, "return_type": return_type})
		return response.new(false, failures.INVALID_SELECTION)
	if not is_available_in_api(prod, api.GITHUB):
		_report_failure("Fetch Asset Failure", "When attempting to fetch a github asset the provided product was not available from github", {"product": prod, "asset_path": asset_path, "return_type": return_types})
		return response.new(false, failures.INVALID_SELECTION)
	var fetch_response : response
	var json_dict : Dictionary[String, Variant]
	var details : Dictionary[String, Variant] = {
		"product": prod, 
		"asset_path": asset_path, 
		"return_type": return_type, 
		"fetch_response": null, 
		}
	fetch_response = _request_url(
		"/repos/NatZombieGames/" + github_product_to_github_name[prod] + "/contents/" + asset_path, 
		["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"], 
		'{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}', 
		"https://api.github.com", 
		)
	if not fetch_response.success:
		_report_failure("Fetch Asset Failure", "Attempting to fetch the asset download url failed", {"product": prod, "asset_path": asset_path, "return_type": return_type, "response_failure": fetch_response.failure, "response_details": fetch_response.details})
		return response.new(false, fetch_response.failure, {"product": prod, "asset_path": asset_path, "return_type": return_type, "response_details": fetch_response.details})
	if asset_path.get_extension() != "":
		fetch_response.returned_str = fetch_response.returned_str.left(fetch_response.returned_str.rfind(',"content":"')) + "}"
	#print(JSON.parse_string(fetch_response.returned_str))
	if typeof(JSON.parse_string(fetch_response.returned_str)) == TYPE_ARRAY:
		details["fetch_response"] = fetch_response
		return response.new(true, failures.NONE, details, return_types.STR, fetch_response.returned_str)
	json_dict.assign(JSON.parse_string(fetch_response.returned_str))
	fetch_response = _request_url(
		json_dict["download_url"], 
		["accept:application/vnd.github+json", "X-GitHub-Api-Version:2022-11-28"], 
		'{"owner":"natzombiegames","repo":"' + github_product_to_github_name[prod].to_snake_case() + '"}', 
		"", return_types.BYT
		)
	if not fetch_response.success:
		_report_failure("Fetch Asset Failure", "Attempting to download the asset failed", {"product": prod, "asset_path": asset_path, "return_type": return_type, "response_failure": fetch_response.failure, "response_details": fetch_response.details})
		return response.new(false, fetch_response.failure, {"product": prod, "asset_path": asset_path, "return_type": return_type, "response_details": fetch_response.details})
	details["fetch_response"] = fetch_response
	return response.new(true, failures.NONE, details, return_types.BYT, "", fetch_response.returned_byt)

##Downloads the latest executable for the given [param prod], returns a [response] with the [member response.returned_byt] being the downloaded executable binary
func download_executable(prod : product) -> response:
	if prod == product.UNKNOWN:
		_report_failure("Download Failure", "When attempting to download an executable the given product was unknown", {"product": prod})
		return response.new(false, failures.INVALID_SELECTION)
	var target : api = get_available_api(prod)
	if target == api.UNKNOWN:
		_report_failure("Download Failure", "When attempting to get an available API for the product: '" + product.find_key(prod) + "' no available API was found", {"product": product, "api": target})
		return response.new(false, failures.INVALID_SELECTION)
	var download_response : response = response.new()
	var details : Dictionary[String, Variant] = {
		"request_response": null, 
		"download_attempt_response": null, 
		"size": 0, 
		"redirects": 0, 
	}
	var download_url : String
	var request_response : Array[response] = fetch_batch(prod, APIManager.batch_types.GENERAL_INFO)
	if not request_response[0].success:
		_report_failure("Download Failure", "Failed to fetch the download url for the product: '" + product.find_key(prod) + "' during download_executable", {"product": prod, "api": target, "failure": request_response[0].failure, "details": request_response[0].details})
		return response.new(false, request_response[0].failure, details)
	details["request_response"] = request_response
	download_url = request_response[1].returned_str
	var version : String = request_response[0].returned_str
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
			main.update_download_visuals(product_to_name[prod], version, platforms.find_key(UserManager.platform), api_to_api_name[target], download_size, Time.get_unix_time_from_system() - start_time, download_progress, last_packet_size, request_host)
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

##Validates the api key for the given [param target], returns a [response]
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
				main.call_deferred(&"create_alert", "Key Validation Failure", "Your Itch.io key was found to be invalid;\nplease check it and try again.")
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
				main.call_deferred(&"create_alert", "Key Validation Failure", "Your Itch.io key was found to be invalid;\nplease check it and try again.")
				return response.new(false, failures.INVALID_KEY, details)
	return response.new()

##Attempts to connect the given [param client] to the given [param host], returns a [response]
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

##Request the content from the given [param url] using the given [param headers], [param body] and [param host] while returning content of the given [param return type], returns a [response]
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
						_:
							request_response.failure = failures.UNKNOWN
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
		request_response.details = details
		if request_response.failure != failures.REDIRECT:
			request_response._get_details()
		if request_response.failure == failures.REDIRECT:
			request_response.success = false
			return request_response
	request_response.success = false
	request_response.details = details
	_report_failure("URL-Request Failure", "Failed to request from url", {"url": url, "headers": headers, "body": body, "host": host, "return_type": return_type, "failure": request_response.failure, "details": request_response.details})
	return request_response

##Appends to the [b]UserManager[/b]'s error log using [code]UserManager.append_to_error_log()[/code] with the given [param type], [param description] and [param details].[br][br]And if [param alert] is enabled then an alert will be fired using [member main] [code]create_alert()[/code]
func _report_failure(type : String, description : String, details : Dictionary[String, Variant]) -> void:
	UserManager.append_to_error_log(type, description, details)
	return
