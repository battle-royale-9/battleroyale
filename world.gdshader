shader_type canvas_item;

// Use global coordinates or pass them from your script
uniform vec2 center;      
uniform float radius;     
uniform vec4 zone_color : source_color = vec4(1.0, 0.0, 0.0, 0.4);

// This tells the shader to use the global coordinates of the pixel
varying vec2 world_pos;

void vertex() {
    // This calculates where the vertex is in the game world
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    float dist = distance(world_pos, center);
    
    if (dist < radius) {
        // Creates the "Hole"
        discard; 
    } else {
        // The "Danger Zone"
        COLOR = zone_color;
    }
}