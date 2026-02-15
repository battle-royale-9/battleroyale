extends Area2D

# --- SETTINGS ---
var damage = 10 # LOWERED DAMAGE because it hits 10 times a second! (10 dmg * 10 ticks = 100 DPS)
var hit_interval = 0.25 # How often to hit (in seconds)
var current_time = 0.0

var shooter_node = null 

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. VISUALS
	rotation = 0
	anim.play("default")
	
	# 2. CLEANUP
	await anim.animation_finished
	queue_free()

func _physics_process(delta):
	# 1. Count up the timer
	current_time += delta
	
	# 2. If 0.1 seconds have passed...
	if current_time >= hit_interval:
		current_time = 0.0 # Reset timer
		_deal_tick_damage()

func _deal_tick_damage():
	# 3. Get everyone currently inside the hitbox
	var targets = get_overlapping_bodies() + get_overlapping_areas()
	
	for target in targets:
		# Friendly Fire Check
		if target == shooter_node:
			continue
			
		# Damage Check
		if target.has_method("take_damage"):
			target.take_damage(damage)

# --- SETUP FUNCTION ---
func setup(who_cast_me):
	shooter_node = who_cast_me
	
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		# "WERT" is the new code, or use "XC" if you want it linked to Plant books
		var multiplier = shooter_node.get_damage_multiplier("WERT") 
		damage = int(damage * multiplier)
