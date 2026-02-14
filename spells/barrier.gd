extends Area2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var parry_timer = $ParryTimer

var is_active = false

func _ready():
	# Ensure we start hidden and non-colliding
	deactivate()

func activate():
	#print("DEBUG: Barrier ACTIVATE called")
	is_active = true
	
	# 1. Show the whole node
	show() 
	
	# 2. Force the sprite itself to be visible (just in case)
	sprite.visible = true 
	
	# 3. Force transparency to full (in case an animation left it at 0)
	modulate.a = 1.0 
	sprite.modulate.a = 1.0
	
	collision.disabled = false
	parry_timer.start()
	
	# Visual pop
	scale = Vector2(1.2, 1.2)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func deactivate():
	is_active = false
	hide() # This hides the whole node and children
	sprite.visible = false # Extra safety
	collision.disabled = true
	parry_timer.stop()

# This function will be checked by the Player or Spell when a hit occurs
func get_shield_status():
	if not is_active:
		return "NONE"
	
	if not parry_timer.is_stopped():
		#print("DEBUG: Status requested - PARRY window active!")
		return "PARRY" 
	
	return "BLOCK"
