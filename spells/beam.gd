extends Area2D

var damage = 5
var shooter_node = null # <--- STORES WHO FIRED THIS
var silenced_duration = 1.5

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. CONNECT SIGNALS
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	# 2. Play Animation
	anim.play("default")
	
	# 3. Wait for animation to finish, then delete
	await anim.animation_finished
	queue_free()

# --- SETUP FUNCTION (UPDATED) ---
func setup(who_fired_me, rotation_angle):
	shooter_node = who_fired_me
	rotation = rotation_angle # Point the beam where we aimed!
	
	# --- DAMAGE SCALING LOGIC ---
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		# "SD" is the ID for Beam
		var multiplier = shooter_node.get_damage_multiplier("SD")
		damage = int(damage * multiplier)

# --- COLLISION LOGIC ---
func _on_hit(target):
	# 1. FRIENDLY FIRE SAFETY
	if target == shooter_node:
		return

	# 2. DAMAGE LOGIC
	if target.has_method("take_damage"):
		target.take_damage(damage)
		
	# 3. SILENCE LOGIC
	if target.has_method("apply_silenced"):
		target.apply_silenced(silenced_duration)
