extends CharacterBody2D

# --- AI BEHAVIOR SETTINGS ---
var move_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
@export var target: Node2D
var speed = 25.0
const WANDER_SPEED = 20.0
const CHASE_SPEED = 35.0
const AGGRO_RADIUS = 200.0
const SPELL_CAST_RANGE = 180.0

# --- HEALTH SETTINGS ---
var health = 25
const MAX_HEALTH = 25

# --- SPELL CASTING SETTINGS ---
var attack_timer = 0.0
const ATTACK_INTERVAL = 3.5
var spell_choice_timer = 0.0
const SPELL_CHOICE_INTERVAL = 10.0 # Change spell preference every 10 seconds
var preferred_spell = 0 # 0=fireball, 1=lightning, 2=beam, 3=plant

# --- SPELL COOLDOWNS (Individual) ---
var cooldown_fireball = 0.0
var cooldown_lightning = 0.0
var cooldown_beam = 0.0
var cooldown_plant = 0.0

const CD_FIREBALL = 4.5
const CD_LIGHTNING = 6.0
const CD_BEAM = 7.0
const CD_PLANT = 8.0

# --- SPELL SCENES ---
var fireball_scene = preload("res://spells_enemy/fireball.tscn")
var lightning_scene = preload("res://spells_enemy/lightning.tscn")
var beam_scene = preload("res://spells_enemy/beam.tscn")
# Note: Plant doesn't exist in spells_enemy, so we'll use a different pattern

# --- LOOT DROPS ---
const BOOK_BEAM = preload("uid://c5a1v8y773lb4")
const BOOK_FIREBALL = preload("uid://dxawtw6wk84pw")
const BOOK_LIGHTNING = preload("uid://dddh7eu8jyb62")
const BOOK_PLANT = preload("uid://clt5hm0m3q51u")

# --- ANIMATION ---
@onready var anim = $AnimatedSprite2D

# --- STATE TRACKING ---
var is_dying = false
var is_casting = false

func _ready() -> void:
	health = MAX_HEALTH
	add_to_group("bots")
	# Random initial spell preference
	preferred_spell = randi() % 4

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	# Update all cooldowns
	update_cooldowns(delta)
	
	# Update timers
	attack_timer += delta
	spell_choice_timer += delta
	
	# Change spell preference periodically for variety
	if spell_choice_timer >= SPELL_CHOICE_INTERVAL:
		preferred_spell = randi() % 4
		spell_choice_timer = 0.0
	
	# Find closest player
	target = get_closest_player()
	
	# AI Behavior
	if target and not is_casting:
		var distance_to_target = position.distance_to(target.position)
		
		if distance_to_target < AGGRO_RADIUS:
			# Chase the player
			var direction = (target.position - position).normalized()
			velocity = direction * CHASE_SPEED
			look_at(target.position)
			
			# Try to cast spell if in range and attack timer is ready
			if distance_to_target < SPELL_CAST_RANGE and attack_timer >= ATTACK_INTERVAL:
				cast_spell()
				attack_timer = 0.0
		else:
			wander_behavior(delta)
	else:
		wander_behavior(delta)
	
	if not is_casting:
		move_and_slide()
	
	# Update animation
	if velocity.length() > 0 and not is_casting:
		anim.play("run")
	elif not is_casting:
		anim.play("idle")

func wander_behavior(delta):
	move_timer -= delta
	
	if move_timer <= 0:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		move_timer = randf_range(2.0, 4.0)
	
	velocity = wander_direction * WANDER_SPEED
	if velocity.length() > 0:
		look_at(position + velocity)

func get_closest_player():
	var all_players = get_tree().get_nodes_in_group("players")
	var closest_player = null
	var shortest_distance = INF
	
	for p in all_players:
		var dist = position.distance_to(p.position)
		if dist < shortest_distance:
			shortest_distance = dist
			closest_player = p
	
	return closest_player

func update_cooldowns(delta):
	if cooldown_fireball > 0:
		cooldown_fireball -= delta
	if cooldown_lightning > 0:
		cooldown_lightning -= delta
	if cooldown_beam > 0:
		cooldown_beam -= delta
	if cooldown_plant > 0:
		cooldown_plant -= delta

func cast_spell():
	if target == null or is_casting:
		return
	
	# Try to cast preferred spell, fallback to available spells
	var spells_to_try = [preferred_spell]
	
	# Add other spells in random order as fallbacks
	for i in range(4):
		if i != preferred_spell:
			spells_to_try.append(i)
	
	# Try each spell until one is available
	for spell_idx in spells_to_try:
		match spell_idx:
			0: # Fireball
				if cooldown_fireball <= 0:
					shoot_fireball()
					cooldown_fireball = CD_FIREBALL
					return
			1: # Lightning
				if cooldown_lightning <= 0:
					shoot_lightning()
					cooldown_lightning = CD_LIGHTNING
					return
			2: # Beam
				if cooldown_beam <= 0:
					shoot_beam()
					cooldown_beam = CD_BEAM
					return
			3: # Plant (simulate with fireball for now since enemy plant doesn't exist)
				if cooldown_plant <= 0:
					shoot_plant_substitute()
					cooldown_plant = CD_PLANT
					return

func shoot_fireball():
	if target == null:
		return
	
	is_casting = true
	velocity = Vector2.ZERO
	anim.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_inside_tree() or target == null:
		is_casting = false
		return
	
	var spell = fireball_scene.instantiate()
	spell.position = position
	# Add inaccuracy - bot aims with ±20 degree randomness
	var direction_vector = (target.position - position).normalized()
	var inaccuracy = deg_to_rad(randf_range(-20, 20))
	direction_vector = direction_vector.rotated(inaccuracy)
	spell.direction = direction_vector
	get_parent().add_child(spell)
	
	is_casting = false

func shoot_lightning():
	if target == null:
		return
	
	is_casting = true
	velocity = Vector2.ZERO
	anim.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_inside_tree() or target == null:
		is_casting = false
		return
	
	var spell = lightning_scene.instantiate()
	# Add inaccuracy - lightning aims with ±50 unit offset
	var target_pos = target.position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	spell.position = target_pos
	get_parent().add_child(spell)
	
	is_casting = false

func shoot_beam():
	if target == null:
		return
	
	is_casting = true
	velocity = Vector2.ZERO
	anim.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_inside_tree() or target == null:
		is_casting = false
		return
	
	var spell = beam_scene.instantiate()
	spell.position = position
	# Add inaccuracy - beam aims with ±15 degree randomness
	var target_direction = position.direction_to(target.position)
	var inaccuracy_angle = deg_to_rad(randf_range(-15, 15))
	var aim_direction = target_direction.rotated(inaccuracy_angle)
	var aim_point = position + aim_direction * 100
	spell.look_at(aim_point)
	get_parent().add_child(spell)
	
	is_casting = false

func shoot_plant_substitute():
	# Since there's no enemy plant spell, shoot 3 fireballs in a spread pattern
	if target == null:
		return
	
	is_casting = true
	velocity = Vector2.ZERO
	anim.play("attack")
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_inside_tree() or target == null:
		is_casting = false
		return
	
	var direction_to_target = (target.position - position).normalized()
	
	# Shoot 3 fireballs in a spread with some inaccuracy
	for i in range(3):
		var spell = fireball_scene.instantiate()
		spell.position = position
		
		# Create spread pattern (-20, 0, +20 degrees) plus random inaccuracy
		var angle_offset = deg_to_rad((i - 1) * 20)
		var inaccuracy = deg_to_rad(randf_range(-10, 10))
		var rotated_direction = direction_to_target.rotated(angle_offset + inaccuracy)
		spell.direction = rotated_direction
		
		get_parent().add_child(spell)
	
	is_casting = false

func take_damage(amount):
	if is_dying:
		return
	
	health -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die():
	if is_dying:
		return
	
	is_dying = true
	velocity = Vector2.ZERO
	
	anim.play("death")
	
	# Drop loot
	drop_loot()
	
	await anim.animation_finished
	queue_free()

func drop_loot():
	# 50% chance to drop a book (nerfed from 80%)
	if randf() < 0.5:
		var book_choices = [BOOK_FIREBALL, BOOK_LIGHTNING, BOOK_BEAM, BOOK_PLANT]
		var chosen_book = book_choices[randi() % book_choices.size()]
		
		var book = chosen_book.instantiate()
		book.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(book)
