extends CharacterBody2D

const SPEED = 100.0
var target_position = Vector2.ZERO
var key_history = ""

# --- PRELOAD EVERYTHING ---
var epstein_scene = preload("res://spells/epstein.tscn")
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")

# NOTICE: The "dummy_scene" preload is DELETED.
# NOTICE: The "spawn_test_dummy" function is DELETED.

func _ready():
	target_position = position
	# NOTICE: No more spawning code here!

func _input(event):
	# 1. COMBO CHECKER
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		if key_history.length() > 10: key_history = key_history.right(10)
		
		print("Combo: ", key_history)
		
		# PROJECTILES
		if key_history.ends_with("EPSTEIN"):
			cast_spell(epstein_scene)
			key_history = ""
			
		if key_history.ends_with("23"):
			cast_spell(fireball_scene)
			key_history = "" 
			
		# SUMMONS
		if key_history.ends_with("WE"):
			summon_spell(lightning_scene)
			key_history = "" 
			
		# BEAMS
		if key_history.ends_with("SD"):
			cast_beam(beam_scene)
			key_history = "" 

	# 2. MOVEMENT CLICK
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()

func _physics_process(_delta):
	if position.distance_to(target_position) > 5:
		velocity = position.direction_to(target_position) * SPEED
		move_and_slide()
	else:
		velocity = Vector2.ZERO

# --- SPELLCASTING FUNCTIONS ---

# For Projectiles (Fireball)
func cast_spell(spell_to_cast):
	var spell_instance = spell_to_cast.instantiate()
	spell_instance.position = position
	spell_instance.direction = (get_global_mouse_position() - position).normalized()
	get_parent().add_child(spell_instance)

# For AOE/Summons (Lightning)
func summon_spell(spell_to_summon):
	var spell_instance = spell_to_summon.instantiate()
	spell_instance.position = get_global_mouse_position()
	get_parent().add_child(spell_instance)

# For Stationary Beams
func cast_beam(spell_to_cast):
	var spell_instance = spell_to_cast.instantiate()
	spell_instance.position = position
	spell_instance.look_at(get_global_mouse_position())
	get_parent().add_child(spell_instance)
