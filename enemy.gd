extends CharacterBody2D
var move_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
@export var target: Node2D
var speed=30
func _physics_process(delta: float) -> void:
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
