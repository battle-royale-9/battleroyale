extends CharacterBody2D

# --- BOT SETTINGS ---
const SPEED = 50.0            # Speed while wandering
const CHASE_SPEED = 75.0      # Speed while fighting
const WANDER_RADIUS = 150.0   # How far it can roam from home
const LEASH_DISTANCE = 300.0  # Max distance from home before it ignores you and goes back
const AGGRO_RADIUS = 400.0    # Distance to notice a player
const DAMAGE_REDUCTION = 0.7  # 30% Nerf
const CAST_TIME = 0.5

# --- COMBAT DISTANCES ---
const COMBAT_DISTANCE = 220.0 
const ATTACK_RANGE = 350.0

# --- AI STATE VARIABLES ---
@onready var home_position = global_position 
var target_position = Vector2.ZERO
var wander_timer = 0.0

var target_node = null 
var last_known_target_pos = Vector2.ZERO 
var is_casting = false 
var is_silenced = false
var is_dying = false

# --- HEALTH & SPELLS ---
var max_hp = 50      
var current_hp = 50   
var current_cooldowns = {"23": 0.0, "WE": 0.0, "SD": 0.0}
const MAX_COOLDOWNS = {"23": 5.0, "WE": 8.0, "SD": 12.0}

# --- NODES ---
@onready var anim = $AnimatedSprite2D
@onready var cast_bar = $CastBar 
@onready var barrier = $Barrier 
@onready var hp_bar = get_node_or_null("CanvasLayer/ProgressBar")

# --- PRELOADS ---
var fireball_scene = preload("res://spells/fireball.tscn")
var lightning_scene = preload("res://spells/Lightning.tscn")
var beam_scene = preload("res://spells/beam.tscn")

signal player_died(player)

func _ready():
	add_to_group("players")
	if home_position == Vector2.ZERO: home_position = global_position
	pick_new_wander_target()
	if hp_bar: hp_bar.max_value = max_hp

func _physics_process(delta):
	if is_dying: return
	process_cooldowns(delta)
	
	# 1. Check Leash: If too far from home, force return and ignore players
	var dist_to_home = global_position.distance_to(home_position)
	
	if dist_to_home > LEASH_DISTANCE:
		target_node = null # Stop chasing
		_move_to_position(home_position, CHASE_SPEED)
	else:
		# 2. Try to find a target if we don't have one
		find_closest_target()
		
		if target_node and is_instance_valid(target_node):
			_combat_state(delta)
		else:
			_wander_state(delta)
	
	move_and_slide()
	_handle_animations()

# --- STATE: WANDER (Monster Script Logic) ---
func _wander_state(delta):
	if global_position.distance_to(target_position) > 15.0:
		_move_to_position(target_position, SPEED)
	else:
		velocity = Vector2.ZERO
		
	wander_timer -= delta
	if wander_timer <= 0:
		pick_new_wander_target()
		wander_timer = randf_range(2.0, 4.0) # Wait a bit between roams

func pick_new_wander_target():
	var rx = randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	var ry = randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	# Wander relative to HOME
	target_position = home_position + Vector2(rx, ry)

# --- STATE: COMBAT ---
func _combat_state(delta):
	var dist_to_player = global_position.distance_to(target_node.global_position)
	
	# Position itself relative to player
	if dist_to_player > COMBAT_DISTANCE + 20:
		_move_to_position(target_node.global_position, CHASE_SPEED)
	elif dist_to_player < COMBAT_DISTANCE - 20:
		# Back up
		velocity = target_node.global_position.direction_to(global_position) * CHASE_SPEED
	else:
		velocity = Vector2.ZERO
	
	# Cast Spells
	if dist_to_player < ATTACK_RANGE and not is_casting:
		decide_attack()

# --- HELPERS ---
func _move_to_position(pos, move_speed):
	velocity = global_position.direction_to(pos) * move_speed

func _handle_animations():
	if velocity.length() > 5:
		anim.play("run")
		anim.flip_h = velocity.x < 0
	elif not is_attacking():
		anim.play("idle")

func find_closest_target():
	var all_players = get_tree().get_nodes_in_group("players")
	var closest = null
	var shortest = AGGRO_RADIUS
	
	for p in all_players:
		if p == self or p.is_dying: continue
		var d = global_position.distance_to(p.global_position)
		if d < shortest:
			shortest = d
			closest = p
	target_node = closest

# --- SPELL SYSTEM (SAME AS BEFORE, NERFED) ---
func decide_attack():
	if is_silenced: return
	last_known_target_pos = target_node.global_position
	if current_cooldowns["WE"] <= 0: start_windup("WE", lightning_scene, "summon")
	elif current_cooldowns["SD"] <= 0: start_windup("SD", beam_scene, "beam")
	elif current_cooldowns["23"] <= 0: start_windup("23", fireball_scene, "cast")

func start_windup(id, scene, type):
	is_casting = true
	cast_bar.visible = true
	cast_bar.value = 0
	var tween = create_tween()
	tween.tween_property(cast_bar, "value", CAST_TIME, CAST_TIME)
	tween.finished.connect(func(): _release_spell(id, scene, type))

func _release_spell(id, scene, type):
	is_casting = false
	cast_bar.visible = false
	if is_silenced or is_dying: return
	
	var s = scene.instantiate()
	get_parent().add_child(s)
	s.global_position = global_position
	if "damage" in s: s.damage *= DAMAGE_REDUCTION
	
	match type:
		"cast":
			var dir = global_position.direction_to(last_known_target_pos)
			if s.has_method("setup"): s.setup(self, dir)
		"summon":
			s.global_position = last_known_target_pos
			if s.has_method("setup"): s.setup(self)
		"beam":
			s.look_at(last_known_target_pos)
			if s.has_method("setup"): s.setup(self, s.rotation)
	
	current_cooldowns[id] = MAX_COOLDOWNS[id]

func process_cooldowns(delta):
	for key in current_cooldowns:
		if current_cooldowns[key] > 0: current_cooldowns[key] -= delta

func take_damage(amount):
	if is_dying: return
	current_hp -= amount
	if hp_bar: hp_bar.value = current_hp
	if current_hp <= 0: die()

func die():
	if is_dying: return
	is_dying = true
	
	# 1. Notify the world
	emit_signal("player_died", self)
	
	# 2. Stop movement and physics
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 3. Play animation
	if anim.sprite_frames.has_animation("die"):
		anim.play("die")
		
		# 4. Wait for animation or a safety timeout (2 seconds)
		# This prevents the bot from staying if the animation loops
		await get_tree().create_timer(1.5).timeout 
	
	# 5. Totally remove the bot from the game
	queue_free()

func is_attacking() -> bool:
	return (anim.animation == "attack1" or anim.animation == "attack2") and anim.is_playing()
	
func take_ring_damage(amount):
	# We use a simplified version of take_damage 
	# so that the "Hurt" animation doesn't cancel spell casting
	current_hp -= amount
	
	# Optional: Tint the player slightly purple/red while in the gas
	modulate = Color(0.8, 0.2, 0.8) 
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_hp <= 0:
		die()
