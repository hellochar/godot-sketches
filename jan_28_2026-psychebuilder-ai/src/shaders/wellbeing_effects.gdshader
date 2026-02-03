shader_type canvas_item;

uniform float wellbeing : hint_range(0.0, 100.0) = 50.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float saturation_boost : hint_range(-0.5, 0.5) = 0.0;
uniform vec4 low_wellbeing_tint : source_color = vec4(0.4, 0.35, 0.5, 1.0);
uniform vec4 high_wellbeing_tint : source_color = vec4(1.0, 0.98, 0.9, 1.0);

void fragment() {
  vec4 color = texture(TEXTURE, UV);
  float wb_normalized = wellbeing / 100.0;
  float saturation = 0.8 + wb_normalized * 0.4 + saturation_boost;
  vec3 gray = vec3(dot(color.rgb, vec3(0.299, 0.587, 0.114)));
  color.rgb = mix(gray, color.rgb, saturation);
  float vignette_strength = vignette_intensity * (1.0 - wb_normalized);
  vec2 center = UV - vec2(0.5);
  float dist = length(center) * 1.4;
  float vignette = 1.0 - smoothstep(0.4, 1.0, dist) * vignette_strength;
  color.rgb *= vignette;
  vec4 tint = mix(low_wellbeing_tint, high_wellbeing_tint, wb_normalized);
  color.rgb = mix(color.rgb, color.rgb * tint.rgb, 0.15);
  COLOR = color;
}
