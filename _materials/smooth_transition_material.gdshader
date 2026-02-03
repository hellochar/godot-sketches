shader_type canvas_item;
uniform sampler2D gradient;
uniform sampler2D noise;
uniform float noise_scale: hint_range(0.0, 1.0, 0.01) = 1.0f;
uniform float threshold_base: hint_range(0.0, 1.0, 0.01) = 0.5f;
uniform sampler2D pattern;
uniform vec2 pattern_size = vec2(16, 16);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
  float threshold = sin(TIME) * 0.5 + 0.5 + threshold_base;
  // [0, 1]
  float grad_value = texture(gradient, UV).x;
  // noise texture slides from [0, noise_scale] to [-noise_scale, 0] based on threshold
  float noise_value = (texture(noise, UV).x - threshold) * noise_scale;
  
  //vec2 uv_pixel = UV / TEXTURE_PIXEL_SIZE;
  vec2 uv_pixel = VERTEX;
  vec2 pattern_uv_pixel = mod(uv_pixel, pattern_size);
  vec2 pattern_uv = pattern_uv_pixel / pattern_size;
  float pattern_value = texture(pattern, pattern_uv).x * 1.5f;
  
  float value = grad_value + noise_value;
  value = pattern_value * value;
  
  // COLOR.a = value > threshold ? 1.0 : 0.0;
  
  // mix from value-0.05 to value
  
  COLOR.a = smoothstep(0.0, 1.0, mix((1.0 - noise_scale) * (1.0 - threshold), 1.0, (value - threshold) * 10.0));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
