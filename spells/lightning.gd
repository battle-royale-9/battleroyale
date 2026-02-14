extends Area2D

var damage = 20
var shooter_node = null # <--- STORES WHO CAST THIS

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. CONNECT SIGNALS
	# We need to hit BODIES (Players/Enemies) and AREAS (Hitboxes)
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	# 2. Play Animation
	anim.play("default")
	
	# 3. Wait for animation to finish, THEN delete
	await anim.animation_finished
	queue_free()

# --- SETUP FUNCTION ---
# Call this immediately after spawning!
func setup(who_cast_me):
	shooter_node = who_cast_me

# --- COLLISION LOGIC ---
# This function handles BOTH Areas and Bodies
func _on_hit(target):
	# 1. FRIENDLY FIRE SAFETY
	# If the caster is standing in their own lightning, ignore them!
	if target == shooter_node:
		return

	# 2. DAMAGE LOGIC
	# Hits multiple targets! (e.g., hitting 3 enemies at once)
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Note: We do NOT queue_free() here. 
	# Lightning continues to flash and can hit other things entering the zone.
