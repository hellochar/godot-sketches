shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 0.5) = 0.1;
uniform float glow_size : hint_range(0.0, 0.2) = 0.05;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.6, 1.0);
uniform float pulse_speed : hint_range(0.0, 4.0) = 1.0;
uniform float pulse_intensity : hint_range(0.0, 0.5) = 0.1;
uniform float is_processing : hint_range(0.0, 1.0) = 0.0;

float rounded_rect_sdf(vec2 p, vec2 size, float radius) {
  vec2 q = abs(p) - size + radius;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void fragment() {
  vec2 uv = UV * 2.0 - 1.0;
  float aspect = 1.0;
  vec2 size = vec2(1.0 - corner_radius * 2.0, 1.0 - corner_radius * 2.0);
  float d = rounded_rect_sdf(uv, size, corner_radius);
  float pulse = 0.0;
  if (is_processing > 0.5) {
    pulse = sin(TIME * pulse_speed) * pulse_intensity * 0.5 + pulse_intensity * 0.5;
  }
  float glow_alpha = (1.0 - smoothstep(0.0, glow_size, d)) * glow_intensity * (1.0 + pulse);
  float body_alpha = 1.0 - smoothstep(-0.02, 0.02, d);
  vec3 color = base_color.rgb;
  vec3 glow_color = base_color.rgb * 1.5;
  color = mix(color, glow_color, pulse * 0.3);
  float final_alpha = max(body_alpha, glow_alpha * 0.5);
  COLOR = vec4(color, final_alpha * base_color.a);
}
