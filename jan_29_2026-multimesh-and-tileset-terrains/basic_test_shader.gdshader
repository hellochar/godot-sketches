shader_type canvas_item;
uniform vec2 player_position;
uniform float sharpness = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX.x += sin(TIME * 2.0 + VERTEX.y * 0.1) * 5.0;
	VERTEX.y += cos(TIME * 1.5 + VERTEX.x * 0.1) * 5.0;

	vec2 global_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;

	// compute distance from player
	float dist = distance(global_position, player_position);
	// scale down based on distance
	float scale = sharpness * dist / (sharpness * dist + 1.0);
  // VERTEX.xy *= scale;
	VERTEX.xy *= dist / 20.0;
}

void fragment() {
	// Called for every pixel the material is visible on.
  COLOR = texture(TEXTURE, UV);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
