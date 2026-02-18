extends CharacterBody2D

const SPEED = 50.0
const CHASE_SPEED = 75.0
const WANDER_RADIUS = 100.0
const LEASH_DISTANCE = 200.0    # Max distance from home before returning
const AGGRO_RADIUS = 100.0
const ATTACK_RANGE = 40.0
const DAMAGE = 15
const ATTACK_COOLDOWN = 1.0

var health = 30
var wander_time = 0.0
var is_attacking = false
var can_attack = true
var is_dying = false

# Set by Spawner (defaults to current pos if manual)
@onready var home_position = global_position 
var target_position = Vector2()

@onready var anim = $AnimatedSprite2D

# Loot
const BOOK_BEAM = preload("uid://c5a1v8y773lb4")
const BOOK_FIREBALL = preload("uid://dxawtw6wk84pw")
const BOOK_LIGHTNING = preload("uid://dddh7eu8jyb62")
const BOOK_PLANT = preload("uid://clt5hm0m3q51u")

func _ready():
	if home_position == Vector2.ZERO:
		home_position = global_position
	pick_new_target()

func _physics_process(delta: float) -> void:
	if is_dying or is_attacking:
		return
		
	# Leash Logic: Return home if too far
	var dist_home = global_position.distance_to(home_position)
	var target = null
	
	if dist_home < LEASH_DISTANCE:
		target = get_closest_player()

	if target:
		var dist = global_position.distance_to(target.global_position)
		if dist <= ATTACK_RANGE and can_attack:
			attack(target)
		elif dist > ATTACK_RANGE:
			_chase_state(target)
		else:
			velocity = Vector2.ZERO 
			anim.play("idle")
	else:
		_wander_state(delta)
	
	move_and_slide()
	
	# Animation
	if velocity.length() > 0:
		anim.play("run")
		if velocity.x != 0:
			anim.flip_h = velocity.x < 0
	else:
		if not is_attacking:
			anim.play("idle")

func get_closest_player():
	var all_players = get_tree().get_nodes_in_group("players")
	var closest = null
	var shortest = AGGRO_RADIUS
	
	for p in all_players:
		var d = global_position.distance_to(p.global_position)
		if d < shortest:
			shortest = d
			closest = p
	return closest

func _chase_state(target_player):
	velocity = global_position.direction_to(target_player.global_position) * CHASE_SPEED

func _wander_state(delta):
	if global_position.distance_to(target_position) > 10:
		velocity = global_position.direction_to(target_position) * SPEED
	else:
		velocity = Vector2.ZERO
		
	wander_time -= delta
	if wander_time <= 0:
		pick_new_target()
		wander_time = randf_range(1.0, 3.0)

func pick_new_target():
	var rx = randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	var ry = randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	# Wander relative to HOME, not current pos
	target_position = home_position + Vector2(rx, ry)

func attack(target):
	is_attacking = true
	can_attack = false 
	velocity = Vector2.ZERO
	anim.play('attack')
		
	await anim.animation_finished
	
	if target and target.has_method('take_damage') and global_position.distance_to(target.global_position) <= ATTACK_RANGE:
		target.take_damage(DAMAGE)
	
	if not is_inside_tree(): return
	
	is_attacking = false
	anim.play("idle")
	
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	if is_inside_tree(): can_attack = true
	
func take_damage(amount):
	if is_dying: return
	health -= amount
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if health <= 0: die()
		
func die():
	is_dying = true
	anim.play('die')
	# Wait ensures loot drops even if anim fails
	await get_tree().create_timer(0.5).timeout 
	drop_loot()
	queue_free()

func drop_loot():
	if randf() <= 0.75:
		var loot = BOOK_PLANT.instantiate()
		loot.global_position = global_position
		loot.z_index = 1
		get_parent().call_deferred("add_child", loot)
