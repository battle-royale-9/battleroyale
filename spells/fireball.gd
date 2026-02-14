extends Area2D

var direction = Vector2.RIGHT
@export var speed = 700.0 
var damage = 10 
var shooter_node = null # <--- STORES WHO SHOT THIS

func _ready():
	# 1. Rotate to face movement direction
	rotation = direction.angle()
	
	# 2. CONNECT SIGNALS
	area_entered.connect(_on_hit_area) 
	body_entered.connect(_on_hit_body)
	
	# 3. Safety Timer
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

# --- SETUP FUNCTION (CRITICAL) ---
# Call this from your Player/Enemy script immediately after spawning!
func setup(who_shot_me, move_direction):
	shooter_node = who_shot_me
	direction = move_direction
	rotation = direction.angle() # Updates rotation instantly

# --- COLLISION LOGIC ---

# 4. HIT AN AREA (Like Hitboxes or Dummies)
func _on_hit_area(area_we_touched):
	# Friendly Fire Check: Ignore the shooter's own hitboxes
	if area_we_touched == shooter_node:
		return

	if area_we_touched.has_method("take_damage"):
		area_we_touched.take_damage(damage)
		queue_free()

# 5. HIT A BODY (Walls, Players, Enemies)
func _on_hit_body(body_we_hit):
	# Friendly Fire Check: Ignore the shooter's physical body
	if body_we_hit == shooter_node:
		return

	# If we hit a Player or Enemy (Layer 2)
	if body_we_hit.has_method("take_damage"):
		body_we_hit.take_damage(damage)
	
	# Destroy fireball on impact (hitting a Wall OR a Person)
	queue_free()
