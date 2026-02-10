extends CharacterBody2D

const SPEED = 101.0
var target_position = Vector2.ZERO
var key_history = ""

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50  

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar

# --- ANIMATION NODE ---
@onready var anim = $AnimatedSprite2D

# --- PRELOAD EVERYTHING ---
var epstein_scene = preload("res://spells/epstein.tscn")
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")

func _ready():
	target_position = position
	anim.play("idle")
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false 

func _input(event):
	# 1. COMBO CHECKER
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		if key_history.length() > 10: key_history = key_history.right(10)
		
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
	# --- 1. HANDLE MOVEMENT ---
	var is_moving = false
	
	if position.distance_to(target_position) > 5:
		velocity = position.direction_to(target_position) * SPEED
		move_and_slide()
		is_moving = true
		
		# --- SPRITE FLIPPING LOGIC (UPDATED) ---
		# Only flip based on movement if we are NOT attacking.
		# If we ARE attacking, we want to keep looking at the mouse (handled in cast function).
		if not is_attacking(): 
			if velocity.x < 0:
				anim.flip_h = true
			elif velocity.x > 0:
				anim.flip_h = false
	else:
		velocity = Vector2.ZERO
		is_moving = false

	# --- 2. HANDLE ANIMATION STATE ---
	
	if is_hurting():
		return

	if is_attacking():
		return

	if is_moving:
		anim.play("run")
	else:
		anim.play("idle")

# --- HEALTH FUNCTIONS ---

func take_damage(amount):
	current_hp -= amount
	hp_bar.value = current_hp
	
	anim.play("hurt")
	
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		die()

func die():
	print("Player Died!")
	get_tree().reload_current_scene()

# --- HELPER FUNCTIONS ---

func is_hurting() -> bool:
	if anim.animation == "hurt" and anim.is_playing():
		return true
	return false

func is_attacking() -> bool:
	if (anim.animation == "attack1" or anim.animation == "attack2") and anim.is_playing():
		return true
	return false

func play_attack_anim():
	if not is_hurting():
		# --- FACE THE MOUSE (NEW) ---
		# Determine where the mouse is relative to the player
		if get_global_mouse_position().x < position.x:
			anim.flip_h = true  # Mouse is to the left -> Look Left
		else:
			anim.flip_h = false # Mouse is to the right -> Look Right

		var attacks = ["attack1", "attack2"]
		anim.play(attacks.pick_random())

# --- SPELLCASTING FUNCTIONS ---

func cast_spell(spell_to_cast):
	play_attack_anim() 
	var spell_instance = spell_to_cast.instantiate()
	spell_instance.position = position
	spell_instance.direction = (get_global_mouse_position() - position).normalized()
	get_parent().add_child(spell_instance)

func summon_spell(spell_to_summon):
	play_attack_anim() 
	var spell_instance = spell_to_summon.instantiate()
	spell_instance.position = get_global_mouse_position()
	get_parent().add_child(spell_instance)

func cast_beam(spell_to_cast):
	play_attack_anim() 
	var spell_instance = spell_to_cast.instantiate()
	spell_instance.position = position
	spell_instance.look_at(get_global_mouse_position())
	get_parent().add_child(spell_instance)
