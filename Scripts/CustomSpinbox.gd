extends PanelContainer

@export var title : String = "":
	set(val):
		title = val
		$Container/Title.text = title
		$Container/Title.visible = len(title) > 0
@export var value : float = 0.0:
	set(val):
		if val != value:
			if rounder != 0.0:
				val = rounder * roundf(val / rounder)
			value = clampf(val, value_range[0], value_range[1])
			$Container/EntryField.text = str(value).left(len(str(int(value))) + 3)
			$Container/EntryField.caret_column = len(str(value))
			self.emit_signal(&"value_changed", value)
@export var value_range : Vector2 = Vector2(0.0, 10.0):
	set(val):
		value_range = val
		value = value
@export var rounder : float = 1.0:
	set(val):
		rounder = val
		value = value
signal value_changed(new_value : int)

func _ready() -> void:
	$Container/EntryField.text_changed.connect(
		func(nval : String) -> void:
			$Container/EntryField.text = float(nval)
			if float(nval) != value:
				value = value
			return)
	$Container/Buttons/Increment.pressed.connect(func() -> void: value += 1.0; return)
	$Container/Buttons/Decrement.pressed.connect(func() -> void: value -= 1.0; return)
	return
