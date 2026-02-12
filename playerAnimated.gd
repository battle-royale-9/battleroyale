extends CharacterBody2D

const SPEED = 101.0
var target_position = Vector2.ZERO
var key_history = ""

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50  

# --- SPELL UNLOCKS (NEW) ---
# All spells start as FALSE (Locked)
var spells_unlocked = {
	"23": false, 
	"WE": false,
	"SD": false,
	"XC": false
}

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar

# --- SPELL UI NODES ---
@onready var overlay_fireball = $CanvasLayer/SpellBar/FireballBox/CooldownOverlay
@onready var overlay_lightning = $CanvasLayer/SpellBar/LightningBox/CooldownOverlay
@onready var overlay_beam = $CanvasLayer/SpellBar/BeamBox/CooldownOverlay
@onready var overlay_plant = $CanvasLayer/SpellBar/PlantBox/CooldownOverlay

# --- COOLDOWN SETTINGS ---
const MAX_COOLDOWNS = {
	"23": 1.0,  # Fireball
	"WE": 3.0,  # Lightning
	"SD": 5.0,  # Beam
	"XC": 10.0  # Plant (Heal)
}

var current_cooldowns = {
	"23": 0.0,
	"WE": 0.0,
	"SD": 0.0,
	"XC": 0.0
}

# --- ANIMATION NODE ---
@onready var anim = $AnimatedSprite2D

# --- PRELOAD EVERYTHING ---
var epstein_scene = preload("res://spells/epstein.tscn")
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")
var plant_scene = preload("res://spells/plant.tscn")

func _ready():
	target_position = position
	anim.play("idle")
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false 
	
	# Reset overlays
	update_overlay("23", 0)
	update_overlay("WE", 0)
	update_overlay("SD", 0)
	update_overlay("XC", 0)

func _input(event):
	# 1. COMBO CHECKER
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		if key_history.length() > 10: key_history = key_history.right(10)
		
		# --- SPELL CHECKS ---
		
		# FIREBALL ("23")
		if key_history.ends_with("23"):
			if spells_unlocked["23"] == true:
				if current_cooldowns["23"] <= 0:
					cast_spell(fireball_scene)
					start_cooldown("23")         
					key_history = ""
				else:
					print("Fireball on Cooldown!")
			else:
				print("You need to find the Fireball Book first!")

		# LIGHTNING ("WE")
		if key_history.ends_with("WE"):
			if spells_unlocked["WE"] == true:
				if current_cooldowns["WE"] <= 0:
					summon_spell(lightning_scene)
					start_cooldown("WE")
					key_history = ""
				else:
					print("Lightning on Cooldown!")
			else:
				print("You need to find the Lightning Book first!")
				
		# BEAM ("SD")
		if key_history.ends_with("SD"):
			if spells_unlocked["SD"] == true:
				if current_cooldowns["SD"] <= 0:
					cast_beam(beam_scene)
					start_cooldown("SD")
					key_history = ""
				else:
					print("Beam on Cooldown!")
			else:
				print("You need to find the Beam Book first!")

		# PLANT ("XC")
		if key_history.ends_with("XC"):
			if spells_unlocked["XC"] == true:
				if current_cooldowns["XC"] <= 0:
					cast_behind(plant_scene)
					start_cooldown("XC")
					key_history = ""
				else:
					print("Plant on Cooldown!")
			else:
				print("You need to find the Plant Book first!")

		# EPSTEIN (Cheat code? Leaving unlocked)
		if key_history.ends_with("EPSTEIN"):
			cast_spell(epstein_scene)
			key_history = ""

	# 2. MOVEMENT CLICK
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()

func _physics_process(delta):
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

# --- COOLDOWN LOGIC ---

func start_cooldown(combo_key):
	current_cooldowns[combo_key] = MAX_COOLDOWNS[combo_key]
	update_overlay(combo_key, 100)

func process_cooldowns(delta):
	for key in current_cooldowns:
		if current_cooldowns[key] > 0:
			current_cooldowns[key] -= delta 
			var ratio = current_cooldowns[key] / MAX_COOLDOWNS[key]
			update_overlay(key, ratio * 100)
		else:
			current_cooldowns[key] = 0
			update_overlay(key, 0)

func update_overlay(key, percentage):
	var target_overlay = null
	
	match key:
		"23": target_overlay = overlay_fireball
		"WE": target_overlay = overlay_lightning
		"SD": target_overlay = overlay_beam
		"XC": target_overlay = overlay_plant 
	
	if target_overlay:
		target_overlay.value = percentage

# --- UNLOCK LOGIC (NEW) ---

# This function is called by the Book when you pick it up!
func unlock_spell(code_name):
	if code_name in spells_unlocked:
		spells_unlocked[code_name] = true
		print("SPELL UNLOCKED: ", code_name)

# --- HEALTH FUNCTIONS ---

func take_damage(amount):
	current_hp -= amount
	hp_bar.value = current_hp
	anim.play("hurt")
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if current_hp <= 0: die()

func heal(amount):
	current_hp += amount
	if current_hp > max_hp:
		current_hp = max_hp
	hp_bar.value = current_hp
	
	modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	print("Healed! Current HP: ", current_hp)

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

func cast_behind(spell_to_cast):
	play_attack_anim()
	var spell_instance = spell_to_cast.instantiate()
	
	# Spawn slightly above the feet
	spell_instance.position = position + Vector2(0, -20)
	
	get_parent().add_child(spell_instance)
