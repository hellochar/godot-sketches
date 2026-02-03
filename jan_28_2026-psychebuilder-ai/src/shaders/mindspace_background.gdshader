shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.12, 0.1, 0.18, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.18, 0.15, 0.25, 1.0);
uniform vec4 accent_color : source_color = vec4(0.25, 0.2, 0.35, 1.0);
uniform float time_of_day : hint_range(0.0, 1.0) = 0.5;
uniform float day_brightness : hint_range(0.8, 1.5) = 1.0;
uniform float night_brightness : hint_range(0.3, 0.8) = 0.5;

void fragment() {
  vec2 uv = UV;
  float gradient = uv.y;
  vec3 base_color = mix(top_color.rgb, bottom_color.rgb, gradient);
  float wave = sin(uv.x * 6.0 + uv.y * 4.0) * 0.5 + 0.5;
  float accent_strength = wave * 0.15 * (1.0 - abs(gradient - 0.5) * 2.0);
  base_color = mix(base_color, accent_color.rgb, accent_strength);
  float brightness = mix(night_brightness, day_brightness, time_of_day);
  COLOR = vec4(base_color * brightness, 1.0);
}
