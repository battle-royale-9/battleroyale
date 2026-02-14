extends Area2D

var heal_amount = 30
var has_healed = false # Ensure we only heal once
var shooter_node = null # <--- STORES WHO CAST THIS

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. DETECT PLAYERS (Bodies)
	body_entered.connect(_on_body_entered)
	
	# 2. PLAY ANIMATION
	anim.play("default")
	
	# 3. THE TIMER LOGIC (Keep existing logic)
	# Wait for animation to finish
	await anim.animation_finished
	
	# Wait 1 extra second
	await get_tree().create_timer(1.0).timeout
	
	# 4. FADE AWAY (The Visual Trick)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Wait for fade to finish, then delete
	await tween.finished
	queue_free()

# --- SETUP FUNCTION ---
# Call this immediately after spawning!
func setup(who_cast_me):
	shooter_node = who_cast_me

# --- COLLISION LOGIC ---
func _on_body_entered(body):
	# CRITICAL CHECK: Is this the person who planted the flower?
	if body == shooter_node:
		# Only heal if we haven't yet
		if not has_healed and body.has_method("heal"):
			body.heal(heal_amount)
			has_healed = true
			print("Caster healed!")
	
	# OPTIONAL: If you want the plant to HURT enemies who step on it:
	# else:
	# 	if body.has_method("take_damage"):
	# 		body.take_damage(10)
