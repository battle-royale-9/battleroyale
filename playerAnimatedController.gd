extends CharacterBody2D

# --- MOVEMENT SETTINGS ---
var speed = 101.0 
const CURSOR_RADIUS = 80.0
const CAST_TIME = 0.5 

var key_history = ""
var last_aim_direction = Vector2.RIGHT
var is_casting = false 
var is_dying = false

# --- HEALTH SETTINGS ---
var max_hp = 50      
var current_hp = 50   

# --- SPELL UNLOCKS ---
var spells_unlocked = {
	"XY": true,     # Fireball
	"YB": true,     # Lightning
	"BX": true,     # Beam
	"AY": true,     # Plant
	"XYAB": false,  # Meteor
	"YBXA": false,  # Tornado
	"BXYA": false,  # Mega Beam
	"AYBX": false   # Poison
}

# --- BOOK COLLECTION ---
# We store these using CONTROLLER CODES
var book_counts = { "XY": 0, "YB": 0, "BX": 0, "AY": 0 }

# --- UI NODES ---
@onready var hp_bar = $CanvasLayer/ProgressBar
@onready var hp_label = $CanvasLayer/ProgressBar/HPLabel
@onready var status_label = $spell_status
@onready var cast_bar = $CastBar 
@onready var barrier = $Barrier 
var status_start_pos = Vector2.ZERO

# --- CURSOR NODE ---
@onready var aim_cursor = $AimCursor

# --- UI OVERLAYS ---
@onready var overlay_fireball = $CanvasLayer/SpellBar/BottomRow/FireballBox/CooldownOverlay
@onready var overlay_lightning = $CanvasLayer/SpellBar/BottomRow/LightningBox/CooldownOverlay
@onready var overlay_beam = $CanvasLayer/SpellBar/BottomRow/BeamBox/CooldownOverlay
@onready var overlay_plant = $CanvasLayer/SpellBar/BottomRow/PlantBox/CooldownOverlay

@onready var overlay_ult_fireball = $CanvasLayer/SpellBar/TopRow/FireballUltBox/CooldownOverlay
@onready var overlay_ult_lightning = $CanvasLayer/SpellBar/TopRow/LightningUltBox/CooldownOverlay
@onready var overlay_ult_beam = $CanvasLayer/SpellBar/TopRow/BeamUltBox/CooldownOverlay
@onready var overlay_ult_plant = $CanvasLayer/SpellBar/TopRow/PlantUltBox/CooldownOverlay

# --- LOCK ICONS ---
@onready var lock_ult_fireball = $CanvasLayer/SpellBar/TopRow/FireballUltBox/LockIcon
@onready var lock_ult_lightning = $CanvasLayer/SpellBar/TopRow/LightningUltBox/LockIcon
@onready var lock_ult_beam = $CanvasLayer/SpellBar/TopRow/BeamUltBox/LockIcon
@onready var lock_ult_plant = $CanvasLayer/SpellBar/TopRow/PlantUltBox/LockIcon

# --- COOLDOWNS ---
const MAX_COOLDOWNS = {
	"XY": 1.0, 
	"YB": 3.0, 
	"BX": 5.0, 
	"AY": 10.0,
	"XYAB": 15.0,
	"YBXA": 15.0,
	"BXYA": 15.0,
	"AYBX": 15.0
}

var current_cooldowns = {
	"XY": 0.0, "YB": 0.0, "BX": 0.0, "AY": 0.0,
	"XYAB": 0.0, "YBXA": 0.0, "BXYA": 0.0, "AYBX": 0.0
}

# --- ANIMATION ---
@onready var anim = $AnimatedSprite2D

# --- PRELOADS ---
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")
var plant_scene = preload("res://spells/plant.tscn")

var meteor_scene = preload("res://spells/meteor.tscn")
var tornado_scene = preload("res://spells/tornado.tscn")
var poison_scene = preload("res://spells/poison.tscn") 
var big_beam_scene = preload("res://spells/beam.tscn") 

func _ready():
	anim.play("idle")
	hp_bar.max_value = max_hp
	update_hp_ui()
	
	cast_bar.visible = false
	cast_bar.max_value = CAST_TIME
	cast_bar.value = 0
	
	status_start_pos = status_label.position
	status_label.visible = false
	
	_reset_ui()
	aim_cursor.position = last_aim_direction * CURSOR_RADIUS
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	if event.is_action("joy_barrier"): 
		if event.is_pressed(): barrier.activate()
		else: barrier.deactivate()

	if is_casting: return

	if event is InputEventJoypadButton and event.pressed:
		if event.is_action("btn_x"): key_history += "X"
		elif event.is_action("btn_y"): key_history += "Y"
		elif event.is_action("btn_b"): key_history += "B"
		elif event.is_action("btn_a"): key_history += "A"
		
		if key_history.length() > 8: key_history = key_history.right(8)
		
		# --- ULTIMATE CHECK ---
		if key_history.ends_with("XABY"): 
			start_windup("XYAB", meteor_scene, "summon", CAST_TIME * 2.0)
		elif key_history.ends_with("YBAX"): 
			start_windup("YBXA", tornado_scene, "summon", CAST_TIME * 2.0)
		elif key_history.ends_with("BXYA"): 
			start_windup("BXYA", big_beam_scene, "beam", CAST_TIME * 2.0)
		elif key_history.ends_with("AYXB"): 
			start_windup("AYBX", poison_scene, "center", CAST_TIME * 2.0)

		# --- BASIC SPELL CHECK ---
		elif key_history.ends_with("XY"): start_windup("XY", fireball_scene, "cast")
		elif key_history.ends_with("YB"): start_windup("YB", lightning_scene, "summon")
		elif key_history.ends_with("BX"): start_windup("BX", beam_scene, "beam")
		elif key_history.ends_with("AY"): start_windup("AY", plant_scene, "behind")

# --- BOOK COLLECTION ---
func collect_book(book_name):
	var spell_key = ""
	match book_name:
		"book_fireball": spell_key = "XY"
		"book_lightning": spell_key = "YB"
		"book_beam": spell_key = "BX"
		"book_tree": spell_key = "AY"
	
	if spell_key != "":
		unlock_spell(spell_key)
		if book_counts[spell_key] >= 3:
			match spell_key:
				"XY": unlock_spell("XYAB")
				"YB": unlock_spell("YBXA")
				"BX": unlock_spell("BXYA")
				"AY": unlock_spell("AYBX")

# --- WIND-UP SYSTEM ---
func start_windup(id, scene, type, time_override = CAST_TIME):
	if spells_unlocked.get(id, false) and current_cooldowns.get(id, 0.0) <= 0:
		is_casting = true
		key_history = "" 
		cast_bar.value = 0
		cast_bar.visible = true
		cast_bar.max_value = time_override
		
		var tween = create_tween()
		tween.tween_property(cast_bar, "value", time_override, time_override)
		tween.finished.connect(func(): _release_spell(id, scene, type))
		
	elif not spells_unlocked.get(id, false):
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
		"center": cast_center(scene) 
	start_cooldown(id)

# --- PHYSICS ---
func _physics_process(delta):
	process_cooldowns(delta)
	var move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_input.length() > 0.1:
		velocity = move_input * speed
		if not is_attacking():
			anim.play("run")
			anim.flip_h = move_input.x < 0
	else:
		velocity = Vector2.ZERO
		if not is_attacking() and not is_hurting():
			anim.play("idle")
	move_and_slide()

	var aim_input = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_input.length() > 0.1:
		last_aim_direction = aim_input.normalized()
	
	if aim_cursor:
		aim_cursor.position = last_aim_direction * CURSOR_RADIUS
		aim_cursor.rotation = last_aim_direction.angle()

# --- UI & LOGIC ---
func update_hp_ui():
	hp_bar.value = current_hp
	var display_hp = int(round(current_hp))
	hp_label.text = str(display_hp) + " / " + str(max_hp)

func _reset_ui():
	update_overlay("XY", 0)
	update_overlay("YB", 0)
	update_overlay("BX", 0)
	update_overlay("AY", 0)
	update_overlay("XYAB", 0)
	update_overlay("YBXA", 0)
	update_overlay("BXYA", 0)
	update_overlay("AYBX", 0)
	
	lock_ult_fireball.visible = true
	lock_ult_lightning.visible = true
	lock_ult_beam.visible = true
	lock_ult_plant.visible = true

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
		"XY": target_overlay = overlay_fireball
		"YB": target_overlay = overlay_lightning
		"BX": target_overlay = overlay_beam
		"AY": target_overlay = overlay_plant 
		"XYAB": target_overlay = overlay_ult_fireball
		"YBXA": target_overlay = overlay_ult_lightning
		"BXYA": target_overlay = overlay_ult_beam
		"AYBX": target_overlay = overlay_ult_plant
	if target_overlay: target_overlay.value = percentage

func unlock_spell(code_name):
	if code_name.length() == 4:
		if code_name in spells_unlocked:
			spells_unlocked[code_name] = true
			show_status_text("ULTIMATE UNLOCKED!")
			match code_name:
				"XYAB": lock_ult_fireball.visible = false
				"YBXA": lock_ult_lightning.visible = false
				"BXYA": lock_ult_beam.visible = false
				"AYBX": lock_ult_plant.visible = false
	
	elif code_name.length() == 2:
		if code_name in book_counts:
			book_counts[code_name] += 1
			show_status_text(code_name + " Power Up!")

# --- CRITICAL FIX: MAP SPELL KEYS TO CONTROLLER KEYS ---
func get_damage_multiplier(spell_key):
	# 1. Translate Keyboard Keys (from Spells) to Controller Keys (stored here)
	var lookup_key = spell_key
	match spell_key:
		"23": lookup_key = "XY"
		"WE": lookup_key = "YB"
		"SD": lookup_key = "BX"
		"XC": lookup_key = "AY"
	
	# 2. Logic (Ultimates = 1.0, Others = 1.0 + Books)
	if lookup_key.length() > 2: 
		return 1.0 
	
	return 1.0 + (book_counts.get(lookup_key, 0) * 0.1)

# --- HEALTH & HELPERS ---
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

func die():
	is_dying = true
	velocity = Vector2.ZERO
	anim.play('die')
	await anim.animation_finished
	queue_free()
func is_hurting() -> bool: return anim.animation == "hurt" and anim.is_playing()
func is_attacking() -> bool: return (anim.animation == "attack1" or anim.animation == "attack2") and anim.is_playing()

func play_attack_anim():
	if not is_hurting():
		anim.flip_h = last_aim_direction.x < 0
		anim.play(["attack1", "attack2"].pick_random())

# --- SPELLCASTING ---
func cast_spell(spell_to_cast):
	play_attack_anim() 
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position
	if spell.has_method("setup"): spell.setup(self, last_aim_direction)

func summon_spell(spell_to_summon):
	play_attack_anim() 
	var spell = spell_to_summon.instantiate()
	get_parent().add_child(spell)
	spell.global_position = aim_cursor.global_position
	if spell.has_method("setup"): spell.setup(self)

func cast_beam(spell_to_cast):
	play_attack_anim() 
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position
	spell.rotation = last_aim_direction.angle()
	if spell.has_method("setup"): spell.setup(self, spell.rotation)

func cast_behind(spell_to_cast):
	play_attack_anim()
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position
	if spell.has_method("setup"): spell.setup(self)

func cast_center(spell_to_cast):
	play_attack_anim()
	var spell = spell_to_cast.instantiate()
	get_parent().add_child(spell)
	spell.global_position = global_position 
	if spell.has_method("setup"): spell.setup(self)
