extends PanelContainer

@export var title : String = "Alert":
	set(value):
		title = value
		set_text_callable.call()
@export var body : String = "Text":
	set(value):
		body = value
		set_text_callable.call()
var text : String = "Alert | Type\n────────────\nText":
	set(value):
		text = value
		%Text.text = value
var set_text_callable : Callable = (func() -> void: text = title + "\n" + "".lpad(len(title) + 1, "─") + "\n" + body; return)
const start_pos : Vector2 = Vector2(0.0, 980.0)
const mid_pos : Vector2 = Vector2(100.0, 880.0)
const end_pos : Vector2 = Vector2(100.0, 580.0)
const start_to_mid_trans : Tween.TransitionType = Tween.TRANS_BOUNCE
const start_to_mid_ease : Tween.EaseType = Tween.EASE_OUT
const mid_to_end_ease : Tween.EaseType = Tween.EASE_IN
const start_to_mid_len : float = 0.15
const mid_to_end_len : float = 10.0

func _ready() -> void:
	self.visible = false
	return

func fire(ntitle : String = title, nbody : String = body) -> void:
	title = ntitle
	body = nbody
	self.visible = true
	create_tween().tween_property(self, "position", mid_pos - Vector2(0.0, self.size.y), start_to_mid_len).from(start_pos).set_ease(start_to_mid_ease).set_trans(start_to_mid_trans)
	await create_tween().tween_property(self, "modulate:a", 1.0, start_to_mid_len).from(0.0).set_ease(start_to_mid_ease).set_trans(start_to_mid_trans).finished
	create_tween().tween_property(self, "position", end_pos - Vector2(0.0, self.size.y), mid_to_end_len).from(mid_pos - Vector2(0.0, self.size.y)).set_ease(mid_to_end_ease)
	await create_tween().tween_property(self, "modulate:a", 0.0, mid_to_end_len).from(1.0).set_ease(mid_to_end_ease).finished
	self.queue_free()
	return
