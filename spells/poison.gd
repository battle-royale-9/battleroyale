extends Area2D

# --- SETTINGS ---
@onready var template = $AnimatedSprite2D 

# ADJUST RADIUS HERE: Change this number to match your CollisionShape2D size!
var cloud_radius = 80.0     # <--- INCREASE/DECREASE THIS LINE

var bubble_count = 15       
var duration = 5.0          
var fade_duration = 1.0     # How long the "disappearing" effect takes

# Combat Stats
var damage = 8
var heal_amount = 2
var tick_rate = 0.25
var slow_factor = 0.5
var shooter_node = null
var current_tick_timer = 0.0
var is_fading = false

func _ready():
	template.hide()
	
	for i in bubble_count:
		spawn_delayed_bubble()
	
	# Start the fade-out sequence 1 second before the duration ends
	get_tree().create_timer(duration - fade_duration).timeout.connect(start_fade_out)

func spawn_delayed_bubble():
	var bubble = template.duplicate()
	add_child(bubble)
	
	# Randomize Position inside the cloud_radius
	var random_pos = Vector2(randf_range(-cloud_radius, cloud_radius), randf_range(-cloud_radius, cloud_radius))
	bubble.position = random_pos
	
	var s = randf_range(0.6, 1.2)
	bubble.scale = Vector2(s, s)
	
	bubble.hide()
	await get_tree().create_timer(randf_range(0.0, 1.5)).timeout
	
	if is_instance_valid(bubble) and not is_fading:
		bubble.show()
		bubble.play("default")
		bubble.animation_finished.connect(func(): _on_bubble_finished(bubble))

func _on_bubble_finished(bubble):
	if is_fading: return # Stop restarting bubbles if we are fading out
	
	bubble.hide()
	await get_tree().create_timer(randf_range(0.1, 0.4)).timeout
	
	if is_instance_valid(bubble) and not is_fading:
		var random_pos = Vector2(randf_range(-cloud_radius, cloud_radius), randf_range(-cloud_radius, cloud_radius))
		bubble.position = random_pos
		bubble.show()
		bubble.play("default")

func start_fade_out():
	is_fading = true
	# Use a Tween to smoothly fade the transparency (modulate:a) to zero
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(queue_free)

# --- COMBAT LOGIC ---
func _physics_process(delta):
	current_tick_timer += delta
	if current_tick_timer >= tick_rate:
		current_tick_timer = 0.0
		_do_effects()

func _do_effects():
	# Heal Player
	if is_instance_valid(shooter_node) and shooter_node.has_method("heal"):
		shooter_node.heal(heal_amount)
	
	# THE FIX: We must add bodies AND areas together like the Tornado script does!
	var targets = get_overlapping_bodies() + get_overlapping_areas()
	
	for target in targets:
		if target != shooter_node and target.has_method("take_damage"):
			target.take_damage(damage)
			# print("Poison hit: ", target.name) # Uncomment this to verify in the console

func setup(caster):
	shooter_node = caster
	
	# ADDED: Scale damage based on plant book counts (XCVB)
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		var multiplier = shooter_node.get_damage_multiplier("XCVB")
		damage = int(damage * multiplier)
