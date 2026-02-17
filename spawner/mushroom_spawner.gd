@tool
extends Node2D

@export var monster_scene: PackedScene 
@export var max_mobs: int = 3
@export var spawn_radius: float = 200.0
@export var respawn_delay: float = 10.0

var current_mobs = 0

func _ready():
	# Wait for load to prevent lag
	if not Engine.is_editor_hint():
		await get_tree().create_timer(1.0).timeout
		for i in range(max_mobs):
			spawn_mob()

func spawn_mob():
	# 1. Safety Check: If spawner is gone, don't spawn
	if current_mobs >= max_mobs or monster_scene == null or not is_inside_tree(): return

	var mob = monster_scene.instantiate()
	
	# Set "Home" to Spawner Center
	mob.home_position = global_position
	
	# Random Pos in Circle
	var angle = randf() * TAU 
	var dist = sqrt(randf()) * spawn_radius 
	mob.global_position = global_position + (Vector2(cos(angle), sin(angle)) * dist)
	
	# --- THE FIX IS HERE ---
	# Instead of current_scene (The UI), add to the Parent (The Map)
	get_parent().call_deferred("add_child", mob)
	# -----------------------
	
	current_mobs += 1
	mob.tree_exited.connect(_on_mob_death)

func _on_mob_death():
	# Crash Check: Stop if game is closing
	if not is_inside_tree(): return

	current_mobs -= 1
	await get_tree().create_timer(respawn_delay).timeout
	spawn_mob()

# Editor Visualizer
func _draw():
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, spawn_radius, Color(1, 0, 0, 0.2))

func _process(delta):
	if Engine.is_editor_hint():
		queue_redraw()
