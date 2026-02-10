extends Area2D

var heal_amount = 30
var has_healed = false # Ensure we only heal once

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. DETECT THE PLAYER
	# Since the Player is a CharacterBody2D, we use 'body_entered'
	# (Lightning used 'area_entered' because enemies are often Areas)
	body_entered.connect(_on_body_entered)
	
	# 2. PLAY ANIMATION
	anim.play("default")
	
	# 3. THE TIMER LOGIC
	# Wait for animation to finish
	await anim.animation_finished
	
	# Wait 1 extra second
	await get_tree().create_timer(1.0).timeout
	
	# 4. FADE AWAY (The Visual Trick)
	var tween = create_tween()
	# Change 'modulate' (transparency) to 0 over 0.5 seconds
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Wait for fade to finish, then delete
	await tween.finished
	queue_free()

func _on_body_entered(body):
	# Only heal if we haven't yet, and if the body can be healed
	if not has_healed and body.has_method("heal"):
		body.heal(heal_amount)
		has_healed = true
		print("Player healed!")
