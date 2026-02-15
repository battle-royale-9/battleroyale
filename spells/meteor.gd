extends Area2D

var damage = 50 
var shooter_node = null 

# --- HITBOX TIMING ---
# Change these numbers to match your explosion animation!
# (Frame 0 is the start. Check your SpriteFrames resource to count.)
var hit_start_frame = 8 
var hit_end_frame = 13

@onready var anim = $AnimatedSprite2D
@onready var col_shape = $CollisionShape2D # Make sure you have a CollisionShape2D!

func _ready():
	# 1. CONNECT SIGNALS
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	# 2. VISUALS
	rotation = 0 
	anim.play("default")
	
	# 3. SAFETY: Start with hitbox OFF so it doesn't hit while falling
	col_shape.disabled = true
	
	# 4. CLEANUP
	await anim.animation_finished
	queue_free()

func _physics_process(_delta):
	# This checks the frame every game tick
	if anim.frame >= hit_start_frame and anim.frame <= hit_end_frame:
		# ENABLE HITBOX (Explosion is happening)
		if col_shape.disabled == true:
			col_shape.disabled = false
	else:
		# DISABLE HITBOX (Falling or Fading out)
		if col_shape.disabled == false:
			col_shape.disabled = true

# --- SETUP FUNCTION ---
func setup(who_cast_me):
	shooter_node = who_cast_me
	
	# --- DAMAGE SCALING ---
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		var multiplier = shooter_node.get_damage_multiplier("23")
		damage = int(damage * multiplier)

# --- COLLISION LOGIC ---
func _on_hit(target):
	if target == shooter_node: return

	if target.has_method("take_damage"):
		target.take_damage(damage)
