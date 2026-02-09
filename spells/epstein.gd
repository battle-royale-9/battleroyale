extends Area2D

var direction = Vector2.RIGHT # Default direction
const SPEED = 300.0

func _ready():
	# Delete self after 5 seconds automatically
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	position += direction * SPEED * delta
