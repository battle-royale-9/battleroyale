extends CharacterBody2D
var move_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
@export var target: Node2D
var speed=30
var health = 30
const MAX_HEALTH = 30

var total_damage = 0
var reset_timer = 0.0
const RESET_TIME = 3.0 

var attack_timer = 0.0
const ATTACK_INTERVAL = 2.0
var fireball_scene = preload("res://spells_enemy/fireball.tscn")

func _ready() -> void:
	health = MAX_HEALTH
	

func _physics_process(delta: float) -> void:
	if health <= 0:
		queue_free()
		return	
	attack_timer += delta
	if attack_timer >= ATTACK_INTERVAL:
		shoot_fireball()
		attack_timer = 0.0
	if target and position.distance_to(target.position) < 400:
		var direction=(target.position - position).normalized()
		velocity = direction*speed
		look_at(target.position)
		move_and_slide()
	else:
		move_timer -= delta
		
		if move_timer <= 0:
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			move_timer = randf_range(1.0, 3.0)
			
		velocity = wander_direction * speed
		if velocity.length() > 0:
			look_at(position + velocity)
		move_and_slide()
		
		
func shoot_fireball():
	if target == null:
		return
	var spell = fireball_scene.instantiate()
	spell.position = position
	var direction_vector = (target.position - position).normalized()
	spell.direction = direction_vector
	get_parent().add_child(spell)

func take_damage(amount):
	health -= amount
	reset_timer = RESET_TIME
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	if health <= 0: queue_free()
