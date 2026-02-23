shader_type canvas_item;
uniform sampler2D noise : repeat_enable;
uniform vec4 color_above : source_color = vec4(0.0);
uniform vec4 color_below : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 color_line : source_color;
uniform float scale = 0.05;
uniform float x_pos = 0.0;
uniform float lift = 0.0;
uniform float y_scale = 1.0;
uniform float time_scale = 0.0;
uniform float line_threshold;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
  float test = texture(noise, vec2((UV.x + x_pos + TIME * time_scale) * scale, 0.5)).r;
  test = mix(0.5, test, y_scale);
  test -= lift;
  float me = UV.y;
  float d = test - me;
  if (abs(d) < line_threshold) {
    COLOR = color_line;
  } else if (d > 0.0) {
    COLOR = color_above;
  } else {
    COLOR = color_below;
  }
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
