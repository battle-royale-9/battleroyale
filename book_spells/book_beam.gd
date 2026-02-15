extends Area2D

func _ready():
	# Keep your floating animation
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check for the NEW function "collect_book"
	if body.has_method("collect_book"):
		# Send the specific name expected by the Player script
		body.collect_book("book_beam")
		print("Beam Book Collected!")
		queue_free()
