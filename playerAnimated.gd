extends CharacterBody2D

const SPEED = 101.0
var target_position = Vector2.ZERO
var key_history = ""

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50  

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar

# --- SPELL UI NODES (UPDATED) ---
# We now talk to the "CooldownOverlay" (TextureProgressBar) inside the box
# If your nodes are named differently, update these paths!
@onready var overlay_fireball = $CanvasLayer/SpellBar/FireballBox/CooldownOverlay
@onready var overlay_lightning = $CanvasLayer/SpellBar/LightningBox/CooldownOverlay
@onready var overlay_beam = $CanvasLayer/SpellBar/BeamBox/CooldownOverlay

# --- COOLDOWN SETTINGS ---
const MAX_COOLDOWNS = {
	"23": 1.0,  # Fireball
	"WE": 3.0,  # Lightning
	"SD": 5.0   # Beam
}

var current_cooldowns = {
	"23": 0.0,
	"WE": 0.0,
	"SD": 0.0
}

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
	
	# Reset overlays to empty at start
	update_overlay("23", 0)
	update_overlay("WE", 0)
	update_overlay("SD", 0)

func _input(event):
	if is_hurting(): return 

	# 1. COMBO CHECKER
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		if key_history.length() > 10: key_history = key_history.right(10)
		
		# --- SPELL CHECKS ---
		
		# FIREBALL ("23")
		if key_history.ends_with("23"):
			if current_cooldowns["23"] <= 0:
				cast_spell(fireball_scene)
				start_cooldown("23")         
				key_history = ""
			else:
				print("Fireball on Cooldown!")

		# LIGHTNING ("WE")
		if key_history.ends_with("WE"):
			if current_cooldowns["WE"] <= 0:
				summon_spell(lightning_scene)
				start_cooldown("WE")
				key_history = ""
			else:
				print("Lightning on Cooldown!")
				
		# BEAM ("SD")
		if key_history.ends_with("SD"):
			if current_cooldowns["SD"] <= 0:
				cast_beam(beam_scene)
				start_cooldown("SD")
				key_history = ""
			else:
				print("Beam on Cooldown!")

		# EPSTEIN (No cooldown)
		if key_history.ends_with("EPSTEIN"):
			cast_spell(epstein_scene)
			key_history = ""

	# 2. MOVEMENT CLICK
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()

func _physics_process(delta):
	# --- HANDLE COOLDOWNS ---
	process_cooldowns(delta)

	# --- 1. HANDLE MOVEMENT ---
	var is_moving = false
	
	if position.distance_to(target_position) > 5:
		velocity = position.direction_to(target_position) * SPEED
		move_and_slide()
		is_moving = true
		
		if not is_attacking(): 
			if velocity.x < 0:
				anim.flip_h = true
			elif velocity.x > 0:
				anim.flip_h = false
	else:
		velocity = Vector2.ZERO
		is_moving = false

	# --- 2. HANDLE ANIMATION STATE ---
	if is_hurting(): return
	if is_attacking(): return

	if is_moving:
		anim.play("run")
	else:
		anim.play("idle")

# --- COOLDOWN LOGIC (UPDATED) ---

func start_cooldown(combo_key):
	# 1. Set the timer
	current_cooldowns[combo_key] = MAX_COOLDOWNS[combo_key]
	# 2. Visually fill the bar to 100% (Dark)
	update_overlay(combo_key, 100)

func process_cooldowns(delta):
	for key in current_cooldowns:
		if current_cooldowns[key] > 0:
			current_cooldowns[key] -= delta 
			
			# CALCULATE PERCENTAGE
			var ratio = current_cooldowns[key] / MAX_COOLDOWNS[key]
			update_overlay(key, ratio * 100)
			var percentage = ratio * 100
			
			# --- ADD THIS DEBUG LINE ---
			#print(key, " Cooldown: ", percentage)
			
		else:
			current_cooldowns[key] = 0
			update_overlay(key, 0) # Clear the shadow

func update_overlay(key, percentage):
	var target_overlay = null
	
	match key:
		"23": target_overlay = overlay_fireball
		"WE": target_overlay = overlay_lightning
		"SD": target_overlay = overlay_beam
	
	if target_overlay:
		target_overlay.value = percentage

# --- HEALTH FUNCTIONS ---

func take_damage(amount):
	current_hp -= amount
	hp_bar.value = current_hp
	anim.play("hurt")
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if current_hp <= 0: die()

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
		if get_global_mouse_position().x < position.x:
			anim.flip_h = true 
		else:
			anim.flip_h = false 
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
