extends CharacterBody2D

const SPEED = 50.0
const CHASE_SPEED = 75.0
const WANDER_RADIUS = 200.0
const AGGRO_RADIUS = 300.0
const ATTACK_RANGE = 40.0
const DAMAGE = 15
const HEALTH = 30
const ATTACK_COOLDOWN = 1.0

@onready var start_position = global_position
var target_position = Vector2()
@onready var anim = $AnimatedSprite2D

var wander_time = 0.0
var is_attacking = false
var can_attack= true

func _ready():
	start_position = global_position
	pick_new_target()

func _physics_process(delta: float) -> void:
	if is_attacking:
		return
	
	var target = get_closest_player()
	
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
	
	if velocity.length() > 0:
		anim.play("run")
		if velocity.x != 0:
			anim.flip_h = velocity.x < 0
	else:
		if not is_attacking:
			anim.play("idle")
	
func get_closest_player():
	var all_players = get_tree().get_nodes_in_group("players")
	var closest_player = null
	var shortest_distance = AGGRO_RADIUS
	
	for p in all_players:
		var distance = global_position.distance_to(p.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			closest_player = p
			
	return closest_player

func _chase_state(target_player):
	var direction = global_position.direction_to(target_player.global_position)
	velocity = direction * CHASE_SPEED

func _wander_state(delta):
	var direction = global_position.direction_to(target_position)
	
	if global_position.distance_to(target_position) > 10:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	wander_time -= delta
	if wander_time <= 0:
		pick_new_target()
		wander_time = randf_range(1.0, 3.0)

func pick_new_target():
	var random_x = randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	var random_y = randf_range(-WANDER_RADIUS, WANDER_RADIUS)
	target_position = start_position + Vector2(random_x, random_y)

func attack(target):
	is_attacking = true
	can_attack = false 
	velocity = Vector2.ZERO
	anim.play('attack')
		
	await anim.animation_finished
	
	var dist = global_position.distance_to(target.global_position)
	if target and target.has_method('take_damage') and dist <= ATTACK_RANGE:
		target.take_damage(DAMAGE)
	
	if not is_inside_tree():
		return
	
	is_attacking = false
	anim.play("idle")
	
	await get_tree().create_timer(ATTACK_COOLDOWN).timeout
	
	if not is_inside_tree():
		return
		
	can_attack = true
