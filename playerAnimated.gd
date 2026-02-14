extends CharacterBody2D

const SPEED = 101.0
const CAST_TIME = 0.3 # Duration of the wind-up/telegraph

var target_position = Vector2.ZERO
var key_history = ""
var is_casting = false # Tracks if we are currently winding up

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
@onready var cast_bar = $CastBar # Set this to Fill: Yellow in Inspector
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

# --- CURSOR NODE ---
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
	
	# Setup Cast Bar
	cast_bar.visible = false
	cast_bar.max_value = CAST_TIME
	cast_bar.value = 0
	
	status_start_pos = status_label.position 
	status_label.visible = false 
	
	_reset_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	# Allow movement clicks even while casting
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()

	# Don't start a NEW spell combo if already winding one up
	if is_casting: return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		
		if key_history.length() > 6: 
			key_history = key_history.right(6)
		
		if key_history.ends_with("23"): start_windup("23", fireball_scene, "cast")
		elif key_history.ends_with("WE"): start_windup("WE", lightning_scene, "summon")
		elif key_history.ends_with("SD"): start_windup("SD", beam_scene, "beam")
		elif key_history.ends_with("XC"): start_windup("XC", plant_scene, "behind")
		elif key_history.ends_with("EPSTEIN"):
			cast_spell(epstein_scene)
			key_history = ""

# --- WIND-UP SYSTEM (NON-BLOCKING MOVEMENT) ---

func start_windup(id, scene, type):
	if spells_unlocked[id] and current_cooldowns[id] <= 0:
		is_casting = true
		key_history = ""
		
		# Visuals
		cast_bar.value = 0
		cast_bar.visible = true
		
		var tween = create_tween()
		# Fills left-to-right over CAST_TIME
		tween.tween_property(cast_bar, "value", CAST_TIME, CAST_TIME)
		tween.finished.connect(func(): _release_spell(id, scene, type))
	elif not spells_unlocked[id]:
		show_status_text("Locked!")
	else:
		show_status_text("Cooldown!")

func _release_spell(id, scene, type):
	is_casting = false
	cast_bar.visible = false
	
	match type:
		"cast": cast_spell(scene)
		"summon": summon_spell(scene)
		"beam": cast_beam(scene)
		"behind": cast_behind(scene)
	
	start_cooldown(id)

# --- PHYSICS & MOVEMENT ---

func _physics_process(delta):
	process_cooldowns(delta)

	var is_moving = false
	
	# MOVEMENT FIX: Removed "if not is_casting" so you can move while winding up
	if position.distance_to(target_position) > 5:
		velocity = position.direction_to(target_position) * SPEED
		move_and_slide()
		is_moving = true
		
		if not is_attacking(): 
			anim.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		is_moving = false

	if is_hurting() or is_attacking(): return 
	
	if aim_cursor:
		aim_cursor.global_position = get_global_mouse_position()

	if is_moving:
		anim.play("run")
	else:
		anim.play("idle")

# --- UI & FEEDBACK ---

func _reset_ui():
	update_overlay("23", 0)
	update_overlay("WE", 0)
	update_overlay("SD", 0)
	update_overlay("XC", 0)
	lock_fireball.visible = true
	lock_lightning.visible = true
	lock_beam.visible = true
	lock_plant.visible = true

func show_status_text(text_content):
	status_label.text = text_content
	status_label.position = status_start_pos
	status_label.modulate.a = 1.0 
	status_label.visible = true
	var tween = create_tween()
	tween.tween_property(status_label, "position:y", -30.0, 0.8).as_relative()
	tween.parallel().tween_property(status_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(status_label.hide)

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
	if target_overlay: target_overlay.value = percentage

func unlock_spell(code_name):
	if code_name in spells_unlocked:
		spells_unlocked[code_name] = true
		show_status_text("Unlocked!")
		match code_name:
			"23": lock_fireball.visible = false
			"WE": lock_lightning.visible = false
			"SD": lock_beam.visible = false
			"XC": lock_plant.visible = false

# --- HEALTH ---

func take_damage(amount):
	if is_casting:
		is_casting = false
		cast_bar.visible = false
		show_status_text("Interrupted!")

	current_hp -= amount
	hp_bar.value = current_hp
	anim.play("hurt")
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if current_hp <= 0: die()

func heal(amount):
	current_hp = min(current_hp + amount, max_hp)
	hp_bar.value = current_hp
	modulate = Color.GREEN
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.3)

func die():
	get_tree().reload_current_scene()

# --- HELPERS ---

func is_hurting() -> bool: return anim.animation == "hurt" and anim.is_playing()
func is_attacking() -> bool: return (anim.animation == "attack1" or anim.animation == "attack2") and anim.is_playing()

func play_attack_anim():
	if not is_hurting():
		anim.flip_h = get_global_mouse_position().x < position.x
		anim.play(["attack1", "attack2"].pick_random())

# --- SPELLCASTING ---

func cast_spell(spell_to_cast):
	play_attack_anim() 
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position
	var direction = (get_global_mouse_position() - global_position).normalized()
	if spell.has_method("setup"): spell.setup(self, direction)

func summon_spell(spell_to_summon):
	play_attack_anim() 
	var spell = spell_to_summon.instantiate()
	get_parent().add_child(spell)
	spell.global_position = get_global_mouse_position()
	if spell.has_method("setup"): spell.setup(self)

func cast_beam(spell_to_cast):
	play_attack_anim() 
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position
	spell.look_at(get_global_mouse_position())
	if spell.has_method("setup"): spell.setup(self, spell.rotation)

func cast_behind(spell_to_cast):
	play_attack_anim()
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position 
	if spell.has_method("setup"): spell.setup(self)
