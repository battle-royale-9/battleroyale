extends Area2D

# --- DAMAGE TRACKING ---
var total_damage = 0
var reset_timer = 0.0
const RESET_TIME = 3.0 

# --- ATTACKING ---
var attack_timer = 0.0
const ATTACK_INTERVAL = 2.0 # Fire every 2 seconds
var fireball_scene = preload("res://spells_enemy/fireball.tscn")

@onready var damage_label = $Label 

func _ready():
	damage_label.text = "0"

func _process(delta):
	# 1. DAMAGE RESET LOGIC (Existing)
	if total_damage > 0:
		reset_timer -= delta
		if reset_timer <= 0:
			total_damage = 0
			damage_label.text = "0"
			modulate = Color.WHITE
			
	# 2. ATTACK LOGIC (New)
	attack_timer += delta
	if attack_timer >= ATTACK_INTERVAL:
		shoot_fireball()
		attack_timer = 0.0 # Reset timer

func shoot_fireball():
	var spell = fireball_scene.instantiate()
	
	# IMPORTANT: Spawn it 50 pixels BELOW the dummy
	# This prevents it from instantly hitting the dummy's own hitbox
	spell.position = position + Vector2(0, 50)
	
	# Set direction to DOWN
	spell.direction = Vector2.DOWN
	
	# Add to the world
	get_parent().add_child(spell)

func take_damage(amount):
	total_damage += amount
	damage_label.text = str(total_damage)
	reset_timer = RESET_TIME
	
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
