extends Area2D

var direction = Vector2.RIGHT
@export var speed = 1500.0 
var damage = 10 # <--- NEW: Set damage amount here

func _ready():
	# 1. Rotate to face movement direction
	rotation = direction.angle()
	
	# 2. CONNECT THE SIGNAL
	# This line tells Godot: "When I touch another Area2D, run the '_on_hit' function"
	area_entered.connect(_on_hit) 
	
	# 3. Safety Timer (delete if misses everything)
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

# 4. THE HIT LOGIC
func _on_hit(area_we_touched):
	# Check if the thing we hit has the "take_damage" function (like your Dummy)
	if area_we_touched.has_method("take_damage"):
		area_we_touched.take_damage(damage)
		
		# Destroy the fireball immediately upon impact
		queue_free()
