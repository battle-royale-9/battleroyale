extends HBoxContainer

# FIXED PATH: Removed the "1" to match your screenshot
@onready var viewport1 = $SubViewportContainer/SubViewport
@onready var viewport2 = $SubViewportContainer2/SubViewport

# You still need to add a Camera2D to the second viewport!
@onready var camera2 = $SubViewportContainer2/SubViewport/Camera2D

# Adjust this path to find your Player 2 inside that "Node2D" map
@onready var player2 = $SubViewportContainer/SubViewport/Node2D/Player2

func _ready():
	# This is the line that was crashing. It should work now.
	viewport2.world_2d = viewport1.world_2d

func _process(delta):
	if player2 and camera2:
		camera2.global_position = player2.global_position
