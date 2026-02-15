extends Area2D

var direction = Vector2.RIGHT
@export var speed = 700.0 
var damage = 10 # This is the BASE damage
var shooter_node = null 

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

# --- SETUP FUNCTION (UPDATED) ---
func setup(who_shot_me, move_direction):
	shooter_node = who_shot_me
	direction = move_direction
	rotation = direction.angle() 

	# --- DAMAGE SCALING LOGIC ---
	# We check if the shooter (the Player) has the book multiplier function
	if shooter_node.has_method("get_damage_multiplier"):
		# "23" is the ID for Fireball in your Player script
		var multiplier = shooter_node.get_damage_multiplier("23")
		
		# Apply the multiplier (e.g., 10 * 1.2 = 12 damage)
		damage = int(damage * multiplier)
		
		# Optional: Print to console so you can verify it works
		print("Fireball Cast! Multiplier: ", multiplier, " | Final Damage: ", damage)

# --- COLLISION LOGIC ---

func _on_hit_area(area_we_touched):
	if area_we_touched == shooter_node: return

	if area_we_touched.has_method("take_damage"):
		area_we_touched.take_damage(damage)
		queue_free()

func _on_hit_body(body_we_hit):
	if body_we_hit == shooter_node: return

	if body_we_hit.has_method("take_damage"):
		body_we_hit.take_damage(damage)
	
	queue_free()
