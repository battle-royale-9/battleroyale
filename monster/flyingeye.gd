extends CharacterBody2D

const SPEED = 50.0
const CHASE_SPEED = 75.0
const WANDER_RADIUS = 200.0
const AGGRO_RADIUS = 100.0
const ATTACK_RANGE = 40.0
const DAMAGE = 15
var health = 30
const ATTACK_COOLDOWN = 1.0


@onready var start_position = global_position
var target_position = Vector2()
@onready var anim = $AnimatedSprite2D

const BOOK_BEAM = preload("uid://c5a1v8y773lb4")
const BOOK_FIREBALL = preload("uid://dxawtw6wk84pw")
const BOOK_LIGHTNING = preload("uid://dddh7eu8jyb62")
const BOOK_PLANT = preload("uid://clt5hm0m3q51u")


var wander_time = 0.0
var is_attacking = false
var can_attack= true
var is_dying = false

func _ready():
	start_position = global_position
	pick_new_target()

func _physics_process(delta: float) -> void:
	if is_dying:
		return
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
	
func take_damage(amount):
	if is_dying:
		return
	health -= amount
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		die()
		
func die():
	is_dying = true
	anim.play('die')

	await get_tree().create_timer(0.5).timeout 
	
	drop_loot()
	queue_free()

func drop_loot():
	if randf() <= 0.2:
		var possible_books = [BOOK_FIREBALL, BOOK_LIGHTNING, BOOK_BEAM, BOOK_PLANT]
		var chosen_book = possible_books.pick_random()
		
		if chosen_book:
			var loot_instance = chosen_book.instantiate()
			loot_instance.global_position = global_position

			get_tree().current_scene.call_deferred("add_child", loot_instance)
