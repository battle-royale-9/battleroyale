extends Area2D

var direction = Vector2.RIGHT
@export var speed = 700.0 
var damage = 10 

func _ready():
	# 1. Rotate to face movement direction
	rotation = direction.angle()
	
	# 2. CONNECT SIGNALS
	# Detect ENEMIES (Areas like the Dummy)
	area_entered.connect(_on_hit_enemy) 
	
	# Detect WALLS (Bodies like the TileMap) <--- NEW!
	body_entered.connect(_on_hit_wall)
	
	# 3. Safety Timer (delete if misses everything)
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

# --- COLLISION LOGIC ---

# 4. HIT AN ENEMY (Area)
func _on_hit_enemy(area_we_touched):
	# Check if the thing we hit has the "take_damage" function
	if area_we_touched.has_method("take_damage"):
		area_we_touched.take_damage(damage)
		queue_free()

# 5. HIT A WALL (Body) <--- NEW!
func _on_hit_wall(body_we_hit):
	# If we hit a wall, floor, or obstacle, just destroy the fireball.
	queue_free()
