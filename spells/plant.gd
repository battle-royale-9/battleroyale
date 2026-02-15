extends Area2D

var heal_amount = 30
var has_healed = false 
var shooter_node = null # <--- STORES WHO CAST THIS

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. DETECT PLAYERS (Bodies)
	body_entered.connect(_on_body_entered)
	
	# 2. PLAY ANIMATION
	anim.play("default")
	
	# 3. THE TIMER LOGIC
	await anim.animation_finished
	await get_tree().create_timer(1.0).timeout
	
	# 4. FADE AWAY
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

# --- SETUP FUNCTION (UPDATED) ---
func setup(who_cast_me):
	shooter_node = who_cast_me
	
	# --- SCALING LOGIC ---
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		# "XC" is the ID for Plant
		var multiplier = shooter_node.get_damage_multiplier("XC")
		
		# Since this is a healing spell, we multiply the HEAL amount
		heal_amount = int(heal_amount * multiplier)

# --- COLLISION LOGIC ---
func _on_body_entered(body):
	# CRITICAL CHECK: Is this the person who planted the flower?
	if body == shooter_node:
		# Only heal if we haven't yet
		if not has_healed and body.has_method("heal"):
			body.heal(heal_amount)
			has_healed = true
			print("Caster healed for: ", heal_amount)
