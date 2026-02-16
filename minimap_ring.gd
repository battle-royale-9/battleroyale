extends Line2D

func _ready():
	# We create a circle with 64 points for smoothness
	var points_array = PackedVector2Array()
	var segments = 64
	
	for i in range(segments):
		var angle = (i * 2.0 * PI) / segments
		# We start with a "Unit Circle" (radius of 1)
		# We will scale this in the main script later
		points_array.append(Vector2(cos(angle), sin(angle)))
	
	self.points = points_array
