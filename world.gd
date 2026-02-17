extends Node2D

@onready var timer_label = $CanvasLayer/TimerLabel
@onready var ring_visual = $RingVisual
@onready var minimap_ring = $CanvasLayer/Minimap/SubViewport/MinimapRing
@onready var player = $Player

# --- PHASE SETTINGS ---
enum Phase { FARM1, SHRINK1, PVP2, SHRINK2, FINAL_PVP, FINAL_SHRINK }
var current_phase = Phase.FARM1
var phase_timer = 60.0 

# --- RING CONSTANTS ---
var possible_centers = [Vector2(1000, 1000), Vector2(1000, -1000), Vector2(-1000, 1000), Vector2(-1000, -1000)]
var current_center = Vector2.ZERO
var target_center = Vector2.ZERO
var chosen_corner = Vector2.ZERO # <--- ADDED: To keep the ring consistent
var current_radius = 3000.0
var target_radius = 3000.0 
var shrink_speed = 0.0
var move_speed = 0.0

var last_print_time = 0

@onready var spawn_point_container: Node = $SpawnPoints

func _ready():
	_setup_minimap_points()
	start_phase(Phase.FARM1)
	spawn_player()

func start_phase(new_phase):
	current_phase = new_phase
	
	match current_phase:
		Phase.FARM1:
			phase_timer = 60.0
			print("PHASE 1: Farming time!")
		
		Phase.SHRINK1:
			phase_timer = 45.0
			select_fixed_sub_circle(1500.0) 
			print("Ring is closing to Phase 2!")
			
		Phase.PVP2:
			phase_timer = 60.0
			print("PHASE 2: PvP time!")
			
		Phase.SHRINK2:
			phase_timer = 45.0
			select_fixed_sub_circle(500.0) # Uses the SAME corner as Phase 1
			print("Ring is closing to Final Zone!")
			
		Phase.FINAL_PVP:
			phase_timer = 30.0
			print("FINAL PHASE: Finish them!")
			
		Phase.FINAL_SHRINK:
			phase_timer = 30.0
			target_radius = 0.0
			# Ensure it collapses on the last known safe spot
			target_center = chosen_corner if chosen_corner != Vector2.ZERO else current_center
			shrink_speed = current_radius / phase_timer
			move_speed = current_center.distance_to(target_center) / phase_timer
			print("SUDDEN DEATH: Total closure!")

func select_fixed_sub_circle(new_radius: float):
	# IF we haven't picked a corner yet, pick one now and LOCK it
	if chosen_corner == Vector2.ZERO:
		chosen_corner = possible_centers.pick_random()
	
	target_center = chosen_corner
	target_radius = new_radius
	
	# Recalculate speeds based on current position and timer
	var distance_to_travel = current_center.distance_to(target_center)
	move_speed = distance_to_travel / phase_timer
	shrink_speed = (current_radius - target_radius) / phase_timer
	
	print("Shrinking towards fixed corner: ", target_center)

func advance_phase():
	var total_phases = Phase.size() 
	var next_idx = int(current_phase) + 1
	
	if next_idx < total_phases:
		start_phase(next_idx as Phase)
	else:
		print("Match Ended!")

func _process(delta):
	# 1. Handle Phase Timer
	phase_timer -= delta
	
	if floor(phase_timer) != last_print_time:
		last_print_time = floor(phase_timer)
		if timer_label:
			timer_label.text = "Phase: " + Phase.keys()[current_phase] + " | " + str(int(phase_timer)) + "s"

	if phase_timer <= 0:
		advance_phase()
		
	# 2. Movement and Shrink Logic
	if current_phase in [Phase.SHRINK1, Phase.SHRINK2, Phase.FINAL_SHRINK]:
		current_radius = move_toward(current_radius, target_radius, shrink_speed * delta)
		current_center = current_center.move_toward(target_center, move_speed * delta)

	# 3. Update Visuals (Shader)
	if ring_visual:
		ring_visual.material.set_shader_parameter("center", current_center)
		ring_visual.material.set_shader_parameter("radius", current_radius)
	
	# 3b. Update Minimap
	if minimap_ring:
		minimap_ring.global_position = current_center
		minimap_ring.scale = Vector2(current_radius, current_radius)

	# 4. Player Damage Logic
	if player:
		var dist = player.global_position.distance_to(current_center)
		if dist > current_radius:
			player.take_ring_damage(5.0 * delta)

func _setup_minimap_points():
	if not minimap_ring: return
	var points = PackedVector2Array()
	for i in range(65):
		var angle = deg_to_rad(i * (360.0 / 64.0))
		points.push_back(Vector2(cos(angle), sin(angle)))
	minimap_ring.points = points
	
func spawn_player():
	var all_spawns = spawn_point_container.get_children()
	var chosen_spawn = all_spawns.pick_random()
	
	player.global_position = chosen_spawn.global_position
	player.target_position = player.global_position
