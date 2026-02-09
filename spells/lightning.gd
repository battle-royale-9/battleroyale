extends Area2D

var damage = 20 # Lightning hits harder than fireballs!

func _ready():
	var anim = $AnimatedSprite2D
	
	# 1. CONNECT THE SIGNAL
	# Detect hits immediately when the lightning spawns/touches something
	area_entered.connect(_on_hit)
	
	# 2. Play Animation
	anim.play("default")
	
	# 3. Wait for animation to finish, THEN delete
	# We do NOT delete in the hit function, because we want the
	# flash to finish playing even if it hits a target.
	await anim.animation_finished
	queue_free()

func _on_hit(area_we_touched):
	if area_we_touched.has_method("take_damage"):
		area_we_touched.take_damage(damage)
		# Note: We do NOT queue_free() here. Let the lightning finish!
