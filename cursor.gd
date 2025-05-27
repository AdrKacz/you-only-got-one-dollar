extends Sprite2D
signal status_updated(is_activated: bool)

var is_activated: bool:
	get:
		return is_activated
	set(value):
		if is_activated == value:
			return # No need to change anything
		is_activated = value
		emit_signal("status_updated", is_activated)
		if is_activated:
			self_modulate = Color.BLACK
		else:
			self_modulate = Color.WHITE

func _process(_delta):
	is_activated = Input.is_action_pressed("Hold")
