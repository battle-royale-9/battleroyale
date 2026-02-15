extends Area2D

# --- SETTINGS ---
var damage = 10 
var hit_interval = 0.25 # Hits 4 times a second
var current_time = 0.0
var lifespan = 5.0 # How long the tornado stays alive (in seconds)

var shooter_node = null 

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. VISUALS
	rotation = 0
	anim.play("default")
	
	# 2. LIFESPAN TIMER (This replaces the await)
	# This creates a timer that deletes the tornado after 'lifespan' seconds
	var timer = get_tree().create_timer(lifespan)
	timer.timeout.connect(queue_free)

func _physics_process(delta):
	# 1. Count up the timer
	current_time += delta
	
	# 2. If hit_interval has passed...
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
		var multiplier = shooter_node.get_damage_multiplier("WERT") 
		damage = int(damage * multiplier)
