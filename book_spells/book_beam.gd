extends Area2D

# The code for Beam is "SD"
var spell_code = "SD"

func _ready():
	# 1. FLOATING ANIMATION
	# This makes the book hover up and down forever
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 5.0, 1.0).as_relative().set_trans(Tween.TRANS_SINE)

	# 2. CONNECT COLLISION
	# Only connect if not already connected via the Inspector
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 1. DEBUG PRINT: See what touched us
	print("Touched by: ", body.name)

	# 2. THE CHECK: "Do you have the ability to unlock spells?"
	# This ignores names like "playerAnimated" or "CharacterBody2D"
	# and just looks for the function inside the script.
	if body.has_method("unlock_spell"):
		body.unlock_spell(spell_code)
		print("Valid player found! Unlocking...")
		queue_free()
