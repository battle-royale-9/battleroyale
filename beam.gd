extends Area2D

var damage = 30 # Beams often do lower damage per tick, or high damage once.

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. CONNECT THE SIGNAL
	# Detect when the beam touches the dummy
	area_entered.connect(_on_hit)
	
	# 2. Start Animation
	anim.play("default")
	
	# 3. Wait for animation to finish, then delete
	await anim.animation_finished
	queue_free()

# 4. THE HIT LOGIC
func _on_hit(area_we_touched):
	# Check if it's a dummy
	if area_we_touched.has_method("take_damage"):
		area_we_touched.take_damage(damage)
		
		# NOTE: We do NOT queue_free() here! 
		# The beam keeps existing so it can hit other enemies behind the first one.
