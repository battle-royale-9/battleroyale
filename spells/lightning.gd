extends Area2D

var damage = 20
var shooter_node = null 

# --- HITBOX TIMING ---
# Lightning usually strikes fast! 
# Adjust these numbers to match when the bolt actually touches the ground.
var hit_start_frame = 2 
var hit_end_frame = 5

@onready var anim = $AnimatedSprite2D
@onready var col_shape = $CollisionShape2D # Ensure you have a CollisionShape2D node!

func _ready():
	# 1. VISUALS
	anim.play("default")
	
	# 2. SAFETY: Start with hitbox OFF so it doesn't hit before the bolt appears
	col_shape.disabled = true
	
	# 3. CONNECT SIGNALS
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	# 4. CLEANUP
	await anim.animation_finished
	queue_free()

func _physics_process(_delta):
	# Check the animation frame every tick
	if anim.frame >= hit_start_frame and anim.frame <= hit_end_frame:
		# ENABLE HITBOX (Bolt is active)
		if col_shape.disabled == true:
			col_shape.disabled = false
	else:
		# DISABLE HITBOX (Fading out or windup)
		if col_shape.disabled == false:
			col_shape.disabled = true

# --- SETUP FUNCTION ---
func setup(who_cast_me):
	shooter_node = who_cast_me
	
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		# "WE" is the ID for Lightning
		var multiplier = shooter_node.get_damage_multiplier("WE")
		damage = int(damage * multiplier)

# --- COLLISION LOGIC ---
func _on_hit(target):
	# 1. FRIENDLY FIRE SAFETY
	if target == shooter_node:
		return

	# 2. DAMAGE LOGIC
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Note: We do NOT queue_free() here.
	# The lightning stays briefly to hit multiple enemies entering the zone.
