extends CharacterBody2D

# --- MOVEMENT SETTINGS ---
# CHANGED: 'const' to 'var' so Poison can slow us down!
var speed = 101.0 
const CAST_TIME = 0.5 

var target_position = Vector2.ZERO
var key_history = ""
var is_casting = false 
var is_silenced = false

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50   

# --- SPELL UNLOCKS ---
var spells_unlocked = {
	"23": true, 
	"WE": true, 
	"SD": true, 
	"XC": true, 
	"2345": false, # Meteor (Fireball Ult)
	"WERT": false, # Tornado (Lightning Ult)
	"XCVB": false  # Poison (Plant Ult) <--- NEW
}

# --- BOOK COLLECTION ---
var book_counts = { "23": 0, "WE": 0, "SD": 0, "XC": 0 }

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar
@onready var hp_label = $CanvasLayer/ProgressBar/HPLabel 
@onready var status_label = $spell_status
@onready var cast_bar = $CastBar 
@onready var barrier = $Barrier 
var status_start_pos = Vector2.ZERO 

# --- SPELL UI NODES (BOTTOM ROW) ---
@onready var overlay_fireball = $CanvasLayer/SpellBar/BottomRow/FireballBox/CooldownOverlay
@onready var overlay_lightning = $CanvasLayer/SpellBar/BottomRow/LightningBox/CooldownOverlay
@onready var overlay_beam = $CanvasLayer/SpellBar/BottomRow/BeamBox/CooldownOverlay
@onready var overlay_plant = $CanvasLayer/SpellBar/BottomRow/PlantBox/CooldownOverlay

# --- SPELL UI NODES (TOP ROW - ULTIMATES) ---
@onready var lock_ult_fireball = $CanvasLayer/SpellBar/TopRow/FireballUltBox/LockIcon
@onready var lock_ult_lightning = $CanvasLayer/SpellBar/TopRow/LightningUltBox/LockIcon
@onready var lock_ult_beam = $CanvasLayer/SpellBar/TopRow/BeamUltBox/LockIcon
@onready var lock_ult_plant = $CanvasLayer/SpellBar/TopRow/PlantUltBox/LockIcon

# --- ULTIMATE COOLDOWN OVERLAYS ---
@onready var overlay_ult_fireball = $CanvasLayer/SpellBar/TopRow/FireballUltBox/CooldownOverlay
@onready var overlay_ult_lightning = $CanvasLayer/SpellBar/TopRow/LightningUltBox/CooldownOverlay 
# NEW: Make sure this node exists!
@onready var overlay_ult_plant = $CanvasLayer/SpellBar/TopRow/PlantUltBox/CooldownOverlay

# --- CURSOR NODE ---
@onready var aim_cursor = $AimCursor

# --- COOLDOWN SETTINGS ---
const MAX_COOLDOWNS = {
	"23": 1.0,  
	"WE": 3.0,  
	"SD": 5.0,  
	"XC": 10.0,
	"2345": 15.0,
	"WERT": 15.0,
	"XCVB": 15.0 # <--- NEW
}

var current_cooldowns = {
	"23": 0.0, "WE": 0.0, "SD": 0.0, "XC": 0.0, 
	"2345": 0.0, "WERT": 0.0, "XCVB": 0.0
}

# --- ANIMATION NODE ---
@onready var anim = $AnimatedSprite2D

# --- TIMER NODE ---
@onready var silenced_timer: Timer = $SilencedTimer

# --- PRELOAD EVERYTHING ---
var epstein_scene = preload("res://spells/epstein.tscn")
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")
var plant_scene = preload("res://spells/plant.tscn")
var meteor_scene = preload("res://spells/meteor.tscn") 
var tornado_scene = preload("res://spells/tornado.tscn")
var poison_scene = preload("res://spells/poison.tscn") # <--- NEW

func _ready():
	target_position = position
	anim.play("idle")
	
	hp_bar.max_value = max_hp
	update_hp_ui() 
	
	cast_bar.visible = false
	cast_bar.max_value = CAST_TIME
	cast_bar.value = 0
	
	status_start_pos = status_label.position 
	status_label.visible = false 
	
	_reset_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = get_global_mouse_position()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed: barrier.activate()
		else: barrier.deactivate()

	if is_casting: return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed = OS.get_keycode_string(event.keycode)
		key_history += key_pressed
		
		if key_history.length() > 10: 
			key_history = key_history.right(10)
		
		# --- SPELL CHECKING ---
		if key_history.ends_with("EPSTEIN"):
			cast_spell(epstein_scene)
			key_history = ""
		
		# ULTIMATES
		elif key_history.ends_with("2345"): 
			start_windup("2345", meteor_scene, "summon", CAST_TIME * 2.0)
		elif key_history.ends_with("WERT"): 
			start_windup("WERT", tornado_scene, "summon", CAST_TIME * 2.0)
		elif key_history.ends_with("XCVB"): # <--- NEW POISON CAST
			start_windup("XCVB", poison_scene, "center", CAST_TIME * 2.0)
			
		# BASIC SPELLS
		elif key_history.ends_with("23"): start_windup("23", fireball_scene, "cast")
		elif key_history.ends_with("WE"): start_windup("WE", lightning_scene, "summon")
		elif key_history.ends_with("SD"): start_windup("SD", beam_scene, "beam")
		elif key_history.ends_with("XC"): start_windup("XC", plant_scene, "behind")

# --- BOOK COLLECTION SYSTEM ---

func collect_book(book_name):
	var spell_key = ""
	match book_name:
		"book_fireball": spell_key = "23"
		"book_lightning": spell_key = "WE"
		"book_beam": spell_key = "SD"
		"book_tree": spell_key = "XC"
	
	if spell_key != "":
		book_counts[spell_key] += 1
		show_status_text("Power Up! (+10%)")
		if book_counts[spell_key] >= 3:
			unlock_ultimate_logic(spell_key)
			show_status_text("ULTIMATE UNLOCKED!")

func unlock_ultimate_logic(key):
	match key:
		"23": 
			lock_ult_fireball.visible = false
			spells_unlocked["2345"] = true
		"WE": 
			lock_ult_lightning.visible = false
			spells_unlocked["WERT"] = true 
		"SD": lock_ult_beam.visible = false
		"XC": 
			lock_ult_plant.visible = false
			spells_unlocked["XCVB"] = true # <--- UNLOCK POISON

func get_damage_multiplier(spell_key):
	if spell_key == "2345": return 1.0 
	if spell_key == "WERT": return 1.0
	if spell_key == "XCVB": return 1.0 # <--- NEW
	return 1.0 + (book_counts[spell_key] * 0.1)

# --- WIND-UP SYSTEM ---

func start_windup(id, scene, type, time_override = CAST_TIME):
	if spells_unlocked.get(id, false) and current_cooldowns.get(id, 0.0) <= 0 and not is_silenced:
		is_casting = true
		key_history = ""
		
		cast_bar.value = 0
		cast_bar.visible = true
		cast_bar.max_value = time_override 
		
		var tween = create_tween()
		tween.tween_property(cast_bar, "value", time_override, time_override)
		tween.finished.connect(func(): _release_spell(id, scene, type))
		
	elif is_silenced: show_status_text("Silenced!") 
	elif not spells_unlocked.get(id, false): show_status_text("Locked!")
	else: show_status_text("Cooldown!")

func _release_spell(id, scene, type):
	if is_silenced:
		is_casting = false
		cast_bar.visible = false
		show_status_text("Silenced!")
		return

	is_casting = false
	cast_bar.visible = false
	
	match type:
		"cast": cast_spell(scene)
		"summon": summon_spell(scene)
		"beam": cast_beam(scene)
		"behind": cast_behind(scene)
		"center": cast_center(scene) # <--- NEW TYPE
	
	start_cooldown(id)

# --- PHYSICS ---

func _physics_process(delta):
	process_cooldowns(delta)
	var is_moving = false
	
	if position.distance_to(target_position) > 5:
		# MOVEMENT FIX: Uses 'speed' variable now
		velocity = position.direction_to(target_position) * speed
		move_and_slide()
		is_moving = true
		if not is_attacking(): anim.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		is_moving = false

	if is_hurting() or is_attacking(): return 
	
	if aim_cursor:
		aim_cursor.global_position = get_global_mouse_position()

	if is_moving: anim.play("run")
	else: anim.play("idle")

# --- UI LOGIC ---

func _reset_ui():
	update_overlay("23", 0)
	update_overlay("WE", 0)
	update_overlay("SD", 0)
	update_overlay("XC", 0)
	update_overlay("2345", 0) 
	update_overlay("WERT", 0) 
	update_overlay("XCVB", 0) # <--- NEW
	
	lock_ult_fireball.visible = true
	lock_ult_lightning.visible = true
	lock_ult_beam.visible = true
	lock_ult_plant.visible = true

func update_hp_ui():
	hp_bar.value = current_hp
	hp_label.text = str(int(round(current_hp))) + " / " + str(max_hp)

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
	if combo_key in MAX_COOLDOWNS:
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
		"2345": target_overlay = overlay_ult_fireball 
		"WERT": target_overlay = overlay_ult_lightning 
		"XCVB": target_overlay = overlay_ult_plant # <--- LINKED HERE
	
	if target_overlay: target_overlay.value = percentage

func unlock_spell(code_name):
	if code_name in spells_unlocked:
		spells_unlocked[code_name] = true
		show_status_text("Unlocked!")

# --- HEALTH & COMBAT ---

func take_damage(amount):
	var shield_status = barrier.get_shield_status()
	if shield_status == "PARRY":
		show_status_text("Parried!")
		return 
	if shield_status == "BLOCK": amount *= 0.8 
	
	if is_casting:
		is_casting = false
		cast_bar.visible = false
		show_status_text("Interrupted!")

	current_hp -= amount
	update_hp_ui() 
	anim.play("hurt")
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if current_hp <= 0: die()

func heal(amount):
	current_hp = min(current_hp + amount, max_hp)
	update_hp_ui() 
	modulate = Color.GREEN
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.3)

func die(): get_tree().reload_current_scene()

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

# NEW: Spawns directly on top of the player
func cast_center(spell_to_cast):
	# No attack animation? Or maybe a 'power up' pose? 
	# Using attack for now to keep it simple.
	play_attack_anim()
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position # Center on player
	if spell.has_method("setup"): spell.setup(self)

# --- SILENCE ---

func apply_silenced(silenced_duration):
	is_silenced = true
	show_status_text("Silenced!") 
	silenced_timer.wait_time = silenced_duration
	silenced_timer.start()

func _on_silenced_timer_timeout() -> void:
	is_silenced = false
	show_status_text("Silence faded")
