extends Area2D

@export var Player = null
var damage = 5
var silenced_duration = 5
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var shooter_node = null

func _ready():
	
	anim.play("default")
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
func setup(who_fired_me, rotation_angle):
	shooter_node = who_fired_me
	
	if shooter_node and shooter_node.has_method("get_damage_multiplier"):
		var multiplier = shooter_node.get_damage_multiplier("SD")
		damage = int(damage * multiplier)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	if body.has_method("apply_silenced"):
		body.apply_silenced(silenced_duration)
