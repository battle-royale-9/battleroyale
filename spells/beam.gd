extends Area2D

var damage = 5
var shooter_node = null # <--- STORES WHO FIRED THIS
var silenced_duration = 1.5

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. CONNECT SIGNALS
	# Beams need to hit Players (Body) and Dummies (Area)
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	# 2. Play Animation
	anim.play("default")
	
	# 3. Wait for animation to finish, then delete
	await anim.animation_finished
	queue_free()

# --- SETUP FUNCTION ---
# Call this immediately! Beams usually need to be ROTATED to face the target.
func setup(who_fired_me, rotation_angle):
	shooter_node = who_fired_me
	rotation = rotation_angle # Point the beam where we aimed!

# --- COLLISION LOGIC ---
func _on_hit(target):
	# 1. FRIENDLY FIRE SAFETY
	# If the beam spawns on top of the shooter, don't hurt them.
	if target == shooter_node:
		return

	# 2. DAMAGE LOGIC
	# The beam pierces! It hits this target and KEEPS GOING.
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if target.has_method("apply_silenced"):
		target.apply_silenced(silenced_duration)
		
	# Note: We do NOT queue_free(). The beam stays until the animation ends.
