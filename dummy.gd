extends Area2D

var total_damage = 0
var reset_timer = 0.0
const RESET_TIME = 3.0 # Reset count if not hit for 3 seconds

# Get reference to the label child node
# "onready" waits until the game starts to find the node
@onready var damage_label = $Label 

func _ready():
	# Initialize the text
	damage_label.text = "0"

func _process(delta):
	# If damage is greater than 0, start counting down to reset
	if total_damage > 0:
		reset_timer -= delta
		
		# If timer hits 0, reset the scoreboard
		if reset_timer <= 0:
			total_damage = 0
			damage_label.text = "0"
			modulate = Color.WHITE # Reset color just in case

func take_damage(amount):
	# 1. Add to the total
	total_damage += amount
	
	# 2. Update the text on screen
	damage_label.text = str(total_damage)
	
	# 3. Reset the "inactivity" timer back to 3 seconds
	reset_timer = RESET_TIME
	
	# 4. Visual Feedback (Flash Red)
	modulate = Color.RED
	
	# Wait 0.1s then turn back to white
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
