// NOTE: Shader automatically converted from Godot Engine 4.6.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform vec3 player_world_position;
uniform float camera_fade_min : hint_range(0.0, 10.0) = 0.5;
uniform float camera_fade_max : hint_range(0.0, 10.0) = 3.0;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
  
  vec3 displacement = vec3(0.0, 0.0, 0.0);
  float local_height = VERTEX.y;

  vec3 vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

  displacement.x += sin(TIME * 2.0 + vertex_world.x * 0.5) * 0.4 * local_height;
  displacement.z += cos(TIME * 1.5 + vertex_world.z * 0.5) * 0.4 * local_height;
  
  // avoid the player

  vec3 player_offset = vertex_world - player_world_position;

//   vec3 instance_world_pos = MODEL_MATRIX[3].xyz;
//   vec3 player_offset = instance_world_pos - player_world_position;

//   float dist = length(player_offset);
//   dist *= dist;
  
//   float power = clamp(150.0 / dist, 0.0, 15.0);
//   displacement.xz += normalize(player_offset.xz) * power * local_height;
  
  vec3 displacement_local = (inverse(MODEL_MATRIX) * vec4(displacement, 0.0)).xyz;
  
  VERTEX += displacement_local;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);

	// Vertex Color Use as Albedo: Enabled
	albedo_tex *= COLOR;

	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	float camera_dist = length(VERTEX);
	float camera_fade = smoothstep(camera_fade_min, camera_fade_max, camera_dist);
	ALPHA *= albedo.a * albedo_tex.a * camera_fade;
}
