extends CharacterBody2D

const SPEED = 300
var target_position = Vector2()
var click_position = Vector2()

func _ready() -> void:
	click_position = position

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("move"):
		click_position = get_global_mouse_position()
	if position.distance_to(click_position) > 3:
		target_position = (click_position - position).normalized()
		velocity = target_position * SPEED
		move_and_slide()
	
