extends Area2D

@export var Player = null
var damage = 5
var silenced_duration = 5
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	
	anim.play("default")
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
	

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	if body.has_method("apply_silenced"):
		body.apply_silenced(silenced_duration)
