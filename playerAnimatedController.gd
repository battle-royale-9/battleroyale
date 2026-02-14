extends CharacterBody2D

const SPEED = 101.0
var key_history = ""
var last_aim_direction = Vector2.RIGHT # Default aim to the right

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50   

# --- SPELL UNLOCKS ---
# We keep the old IDs ("23", "WE") so your books still unlock them correctly.
var spells_unlocked = {
	"23": false, # Fireball (Combo: XY)
	"WE": false, # Lightning (Combo: YB)
	"SD": false, # Beam (Combo: BX)
	"XC": false  # Plant (Combo: AY)
}

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar
@onready var status_label = $spell_status
var status_start_pos = Vector2.ZERO

# --- UI OVERLAYS & LOCKS ---
@onready var overlay_fireball = $CanvasLayer/SpellBar/FireballBox/CooldownOverlay
@onready var overlay_lightning = $CanvasLayer/SpellBar/LightningBox/CooldownOverlay
@onready var overlay_beam = $CanvasLayer/SpellBar/BeamBox/CooldownOverlay
@onready var overlay_plant = $CanvasLayer/SpellBar/PlantBox/CooldownOverlay

@onready var lock_fireball = $CanvasLayer/SpellBar/FireballBox/LockIcon
@onready var lock_lightning = $CanvasLayer/SpellBar/LightningBox/LockIcon
@onready var lock_beam = $CanvasLayer/SpellBar/BeamBox/LockIcon
@onready var lock_plant = $CanvasLayer/SpellBar/PlantBox/LockIcon

# --- COOLDOWNS ---
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

# --- ANIMATION ---
@onready var anim = $AnimatedSprite2D

# --- PRELOADS ---
var epstein_scene = preload("res://spells/epstein.tscn")
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")
var plant_scene = preload("res://spells/plant.tscn")

func _ready():
	anim.play("idle")
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false 
	
	status_start_pos = status_label.position
	status_label.visible = false
	
	# Update Locks & Overlays
	update_overlay("23", 0)
	update_overlay("WE", 0)
	update_overlay("SD", 0)
	update_overlay("XC", 0)
	
	lock_fireball.visible = true
	lock_lightning.visible = true
	lock_beam.visible = true
	lock_plant.visible = true

func _input(event):
	# 1. CONTROLLER BUTTON CHECKER
	if event is InputEventJoypadButton and event.pressed:
		
		# Map buttons to letters for key_history
		if event.is_action("btn_x"): key_history += "X"
		elif event.is_action("btn_y"): key_history += "Y"
		elif event.is_action("btn_b"): key_history += "B"
		elif event.is_action("btn_a"): key_history += "A"
		
		# Limit history length
		if key_history.length() > 10: key_history = key_history.right(10)
		
		# --- SPELL COMBO CHECKS ---
		
		# FIREBALL (XY) -> Uses old ID "23"
		if key_history.ends_with("XY"):
			cast_spell_logic("23", fireball_scene, "cast")

		# LIGHTNING (YB) -> Uses old ID "WE"
		if key_history.ends_with("YB"):
			cast_spell_logic("WE", lightning_scene, "summon")
			
		# BEAM (BX) -> Uses old ID "SD"
		if key_history.ends_with("BX"):
			cast_spell_logic("SD", beam_scene, "beam")

		# PLANT (AY) -> Uses old ID "XC"
		if key_history.ends_with("AY"):
			cast_spell_logic("XC", plant_scene, "behind")

	# Keep Keyboard support for other things (like cheat codes)
	if event is InputEventKey and event.pressed:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		if key_history.length() > 10: key_history = key_history.right(10)
		
		if key_history.ends_with("EPSTEIN"):
			cast_spell(epstein_scene)
			key_history = ""

# Wrapper function to clean up the repeated logic above
func cast_spell_logic(id, scene, type):
	if spells_unlocked[id] == true:
		if current_cooldowns[id] <= 0:
			# Execute the specific type of cast
			if type == "cast": cast_spell(scene)
			elif type == "summon": summon_spell(scene)
			elif type == "beam": cast_beam(scene)
			elif type == "behind": cast_behind(scene)
			
			start_cooldown(id)         
			key_history = ""
		else:
			show_status_text("Cooldown!")
	else:
		show_status_text("Locked!")

func _physics_process(delta):
	process_cooldowns(delta)

	# --- 1. LEFT STICK MOVEMENT ---
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if move_input.length() > 0:
		velocity = move_input * SPEED
		anim.play("run")
	else:
		velocity = Vector2.ZERO
		if not is_attacking() and not is_hurting():
			anim.play("idle")
			
	move_and_slide()

	# --- 2. RIGHT STICK AIMING ---
	var aim_input = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	
	# Only update aim if the stick is actually moving
	if aim_input.length() > 0.1:
		last_aim_direction = aim_input.normalized()
	
	# Flip sprite based on AIM, not movement (allows strafing)
	if not is_attacking() and not is_hurting():
		if last_aim_direction.x < 0:
			anim.flip_h = true
		elif last_aim_direction.x > 0:
			anim.flip_h = false

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
	if current_hp > max_hp: current_hp = max_hp
	hp_bar.value = current_hp
	modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func die():
	print("Player Died!")
	get_tree().reload_current_scene()

# --- HELPER FUNCTIONS ---

func is_hurting() -> bool:
	return anim.animation == "hurt" and anim.is_playing()

func is_attacking() -> bool:
	return (anim.animation == "attack1" or anim.animation == "attack2") and anim.is_playing()

func play_attack_anim():
	if not is_hurting():
		# Face the direction we are aiming
		if last_aim_direction.x < 0:
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
	spell_instance.direction = last_aim_direction
	get_parent().add_child(spell_instance)

func summon_spell(spell_to_summon):
	play_attack_anim() 
	var spell_instance = spell_to_summon.instantiate()
	spell_instance.position = position + (last_aim_direction * 150)
	get_parent().add_child(spell_instance)

func cast_beam(spell_to_cast):
	play_attack_anim() 
	var spell_instance = spell_to_cast.instantiate()
	spell_instance.position = position
	spell_instance.rotation = last_aim_direction.angle()
	get_parent().add_child(spell_instance)

func cast_behind(spell_to_cast):
	play_attack_anim()
	var spell_instance = spell_to_cast.instantiate()
	spell_instance.position = position + Vector2(0, -20)
	get_parent().add_child(spell_instance)
