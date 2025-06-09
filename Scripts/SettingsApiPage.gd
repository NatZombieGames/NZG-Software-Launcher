extends VBoxContainer

func _ready() -> void:
	$ItchKey.text = UserManager.settings[&"ItchAPIKey"]
	$ItchKey.placeholder_text = UserManager.settings[&"ItchAPIKey"]
	$ItchKey.submitted_callable = (func(text : String) -> void: UserManager.settings[&"ItchAPIKey"] = text; APIManager.valid_api_key_cache.erase(APIManager.api.ITCH); return)
	return
