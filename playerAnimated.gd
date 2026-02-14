extends CharacterBody2D

const SPEED = 101.0
var target_position = Vector2.ZERO
var key_history = ""

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50   

# --- SPELL UNLOCKS ---
var spells_unlocked = {
	"23": false, # Fireball
	"WE": false, # Lightning
	"SD": false, # Beam
	"XC": false  # Plant
}

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar
@onready var status_label = $spell_status
var status_start_pos = Vector2.ZERO 

# --- SPELL UI NODES (COOLDOWNS) ---
@onready var overlay_fireball = $CanvasLayer/SpellBar/FireballBox/CooldownOverlay
@onready var overlay_lightning = $CanvasLayer/SpellBar/LightningBox/CooldownOverlay
@onready var overlay_beam = $CanvasLayer/SpellBar/BeamBox/CooldownOverlay
@onready var overlay_plant = $CanvasLayer/SpellBar/PlantBox/CooldownOverlay

# --- SPELL UI NODES (LOCKS) ---
@onready var lock_fireball = $CanvasLayer/SpellBar/FireballBox/LockIcon
@onready var lock_lightning = $CanvasLayer/SpellBar/LightningBox/LockIcon
@onready var lock_beam = $CanvasLayer/SpellBar/BeamBox/LockIcon
@onready var lock_plant = $CanvasLayer/SpellBar/PlantBox/LockIcon

# --- CURSOR NODE (NEW!) ---
@onready var aim_cursor = $AimCursor

# --- COOLDOWN SETTINGS ---
const MAX_COOLDOWNS = {
	"23": 1.0,  
	"WE": 3.0,  
	"SD": 5.0,  
	"XC": 10.0  
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
	
	# Setup Status Label
	status_start_pos = status_label.position 
	status_label.visible = false 
	
	# Reset overlays
	update_overlay("23", 0)
	update_overlay("WE", 0)
	update_overlay("SD", 0)
	update_overlay("XC", 0)
	
	# Ensure Locks are VISIBLE at start
	lock_fireball.visible = true
	lock_lightning.visible = true
	lock_beam.visible = true
	lock_plant.visible = true
	
	# Hide the Windows Mouse (so we only see our custom cursor)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	# 1. COMBO CHECKER
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		
		# Shorten history to 6 characters for faster string matching
		if key_history.length() > 6: 
			key_history = key_history.right(6)
		
		# --- SPELL CHECKS (Using elif to save CPU) ---
		
		# FIREBALL ("23")
		if key_history.ends_with("23"):
			if spells_unlocked["23"]:
				if current_cooldowns["23"] <= 0:
					cast_spell(fireball_scene) 
					start_cooldown("23")          
					key_history = ""
				else:
					show_status_text("Cooldown!")
			else:
				show_status_text("Locked!")

		# LIGHTNING ("WE")
		elif key_history.ends_with("WE"):
			if spells_unlocked["WE"]:
				if current_cooldowns["WE"] <= 0:
					summon_spell(lightning_scene) 
					start_cooldown("WE")
					key_history = ""
				else:
					show_status_text("Cooldown!")
			else:
				show_status_text("Locked!")
				
		# BEAM ("SD")
		elif key_history.ends_with("SD"):
			if spells_unlocked["SD"]:
				if current_cooldowns["SD"] <= 0:
					cast_beam(beam_scene) 
					start_cooldown("SD")
					key_history = ""
				else:
					show_status_text("Cooldown!")
			else:
				show_status_text("Locked!")

		# PLANT ("XC")
		elif key_history.ends_with("XC"):
			if spells_unlocked["XC"]:
				if current_cooldowns["XC"] <= 0:
					cast_behind(plant_scene) 
					start_cooldown("XC")
					key_history = ""
				else:
					show_status_text("Cooldown!")
			else:
				show_status_text("Locked!")

		# CHEAT CODES (Checking specifically for longer strings)
		elif key_history.ends_with("EPSTEIN"):
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
	
	# --- 3. UPDATE CURSOR POSITION (NEW!) ---
	# This forces the AimCursor sprite to stick to the mouse
	if aim_cursor:
		aim_cursor.global_position = get_global_mouse_position()

	if is_moving:
		anim.play("run")
	else:
		anim.play("idle")

# --- VISUAL FEEDBACK ---

func show_status_text(text_content):
	status_label.text = text_content
	status_label.position = status_start_pos
	status_label.modulate.a = 1.0 
	status_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(status_label, "position:y", -30.0, 0.8).as_relative()
	tween.parallel().tween_property(status_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(status_label.hide)

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

# --- UNLOCK LOGIC ---

func unlock_spell(code_name):
	if code_name in spells_unlocked:
		spells_unlocked[code_name] = true
		print("SPELL UNLOCKED: ", code_name)
		
		show_status_text("Unlocked!")
		
		match code_name:
			"23": lock_fireball.visible = false
			"WE": lock_lightning.visible = false
			"SD": lock_beam.visible = false
			"XC": lock_plant.visible = false

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

# --- SPELLCASTING FUNCTIONS (UPDATED FOR UNIVERSAL SPELLS) ---

# 1. FIREBALL (Moving Projectile)
func cast_spell(spell_to_cast):
	play_attack_anim() 
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell) # Add to tree FIRST
	spell.global_position = global_position # Spawn at player
	
	# Calculate Direction
	var mouse_pos = get_global_mouse_position()
	var direction_vector = (mouse_pos - global_position).normalized()
	
	# CRITICAL: Tell the spell who shot it!
	if spell.has_method("setup"):
		spell.setup(self, direction_vector)
	else:
		# Fallback for old spells (like Epstein) if they don't have setup
		spell.direction = direction_vector

# 2. LIGHTNING (Mouse Position Summon)
func summon_spell(spell_to_summon):
	play_attack_anim() 
	var spell = spell_to_summon.instantiate()
	get_parent().add_child(spell)
	spell.global_position = get_global_mouse_position() # Spawn at Mouse
	
	# CRITICAL: Tell lightning who cast it (so you don't zap yourself)
	if spell.has_method("setup"):
		spell.setup(self)

# 3. BEAM (Directional Ray)
func cast_beam(spell_to_cast):
	play_attack_anim() 
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position
	
	# Rotate to face mouse
	spell.look_at(get_global_mouse_position())
	
	# CRITICAL: Pass 'self' and the rotation
	if spell.has_method("setup"):
		spell.setup(self, spell.rotation)

# 4. PLANT (Spawn at Feet)
func cast_behind(spell_to_cast):
	play_attack_anim()
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	
	# Spawn exactly at feet (or slightly offset if you prefer)
	spell.global_position = global_position 
	
	# CRITICAL: Pass 'self' so it knows to HEAL you
	if spell.has_method("setup"):
		spell.setup(self)
