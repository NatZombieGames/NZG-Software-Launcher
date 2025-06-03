extends PanelContainer

@export var title : String = "LineEdit":
	set(value):
		%Title.text = value
	get:
		return %Title.text
@export var text : String = "":
	set(value):
		%LineEdit.text = value
	get:
		return %LineEdit.text
@export var placeholder_text : String = "":
	set(value):
		%LineEdit.placeholder_text = value
	get:
		return %LineEdit.placeholder_text
@export var min_size : Vector2 = Vector2(100.0, 30.0):
	set(value):
		%LineEdit.custom_minimum_size = value
	get:
		return %LineEdit.custom_minimum_size
var submitted_callable : Callable = (func() -> void: return)

func _ready() -> void:
	%LineEdit.text_changed.connect(Callable(self, &"submitted"))
	return

func submitted(txt : String) -> void:
	submitted_callable.call(txt)
	return
