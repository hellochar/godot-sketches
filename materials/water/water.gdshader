shader_type spatial;
// Transparent blending for water in Godot 4 (alpha prepass mode removed in 4.x)
render_mode cull_back, blend_mix, depth_draw_opaque, specular_schlick_ggx, shadows_disabled;

// Scene depth texture (Godot 4 requires explicit uniform with hint)
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

uniform vec4 shallow_color : source_color = vec4(0.12, 0.45, 0.7, 1.0);
uniform vec4 deep_color    : source_color = vec4(0.02, 0.12, 0.25, 1.0);
uniform float amplitude = 0.15;       // vertical displacement
uniform float frequency = 6.0;        // wave frequency
uniform float speed = 1.2;            // wave speed
uniform float metallic_factor = 0.0;
uniform float smoothness = 0.85;      // 0..1 maps to roughness
uniform float water_level = 0.55;     // world Y level of the water plane
// Transparency controls
uniform float base_alpha = 0.6;        // 0 = fully transparent, 1 = opaque
uniform float fresnel_opacity = 0.35;  // extra opacity at grazing angles

// Dual normal maps (tiled) that scroll over time in different directions
uniform sampler2D normal_map_1 : repeat_enable;
uniform sampler2D normal_map_2 : repeat_enable;
uniform vec2 normal1_uv_scale = vec2(2.0, 2.0);
uniform vec2 normal2_uv_scale = vec2(4.0, 4.0);
uniform vec2 normal1_scroll_dir = vec2(0.1, 0.0);
uniform vec2 normal2_scroll_dir = vec2(-0.05, 0.07);
uniform float normal1_speed = 0.6;
uniform float normal2_speed = 0.9;
uniform float normal1_strength = 0.6;  // 0..1 strength for first map
uniform float normal2_strength = 0.7;  // 0..1 strength for second map
uniform float normal_mix = 0.85;       // blend factor when mixing wave normal and texture normals

// Shoreline foam controls using scene depth
uniform vec3 foam_color = vec3(1.0, 1.0, 1.0);
uniform float foam_intensity = 0.8;    // how strongly foam color replaces base
uniform float foam_edge_width = 0.01;  // how far from intersection foam extends (depth units)
uniform float foam_softness = 0.02;    // additional falloff range
uniform float foam_alpha_boost = 0.15; // extra opacity near foam to make it pop

// Simple 2-axis sine/cos waves based on UVs.
float wave_height(vec2 uv, float t) {
	float w = 0.0;
	w += sin(uv.x * frequency + t);
	w += cos(uv.y * frequency * 1.23 - t * 1.07);
	w *= 0.5; // average
	return w * amplitude;
}

vec3 approx_normal(vec2 uv, float t) {
	// Derivatives of the height function with respect to uv
	float dx = cos(uv.x * frequency + t) * frequency * amplitude * 0.5;
	float dy = -sin(uv.y * frequency * 1.23 - t * 1.07) * (frequency * 1.23) * amplitude * 0.5;
	// Convert to a normal in object space (plane lies on XZ with Y up)
	vec3 n = normalize(vec3(-dx, 1.0, -dy));
	return n;
}

void vertex() {
	float t = TIME * speed;
	// Plane UVs assumed; displace along Y
	VERTEX.y += wave_height(UV, t);
	// Update normal approx to respond to light better
	NORMAL = approx_normal(UV, t);
}

void fragment() {
	// Fresnel-ish term for color blending
	float fres = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);
	vec3 base_col = mix(deep_color.rgb, shallow_color.rgb, fres);

	// Sample and combine two scrolling normal maps in tangent space
	vec2 uv1 = UV * normal1_uv_scale + normal1_scroll_dir * (TIME * normal1_speed);
	vec2 uv2 = UV * normal2_uv_scale + normal2_scroll_dir * (TIME * normal2_speed);
	// Decode normals from [0,1] to [-1,1], reconstruct Z
	vec3 n1 = texture(normal_map_1, uv1).xyz * 2.0 - 1.0;
	n1.z = sqrt(max(1.0 - dot(n1.xy, n1.xy), 0.0));
	n1.xy *= normal1_strength;
	n1 = normalize(n1);
	vec3 n2 = texture(normal_map_2, uv2).xyz * 2.0 - 1.0;
	n2.z = sqrt(max(1.0 - dot(n2.xy, n2.xy), 0.0));
	n2.xy *= normal2_strength;
	n2 = normalize(n2);
	vec3 n_ts = normalize(n1 + n2);
	// Transform from tangent space to object (or world) using TBN
	mat3 TBN = mat3(TANGENT, BINORMAL, NORMAL);
	vec3 n_from_textures = normalize(TBN * n_ts);
	// Blend texture normals with existing surface normal (from vertex waves)
	vec3 final_normal = normalize(mix(NORMAL, n_from_textures, normal_mix));

	ALBEDO = base_col;
	METALLIC = metallic_factor;
	ROUGHNESS = clamp(1.0 - smoothness, 0.04, 1.0);
	SPECULAR = 0.5;
	// Optional subtle emission for glow
	EMISSION = base_col * 0.02;
	NORMAL = final_normal;

	// Shoreline foam via scene depth difference (opaque depth vs current fragment)
	float scene_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float my_depth = FRAGCOORD.z;
	float d = clamp(scene_depth - my_depth, 0.0, 1.0);
	// Soft band near intersection
	float foam_edge = 1.0 - smoothstep(0.0, foam_edge_width, d);
	float foam_soft = smoothstep(0.0, foam_softness, d);
	float foam = clamp(foam_edge * foam_soft, 0.0, 1.0);
	// Tiny procedural breakup so foam isn't a perfect line
	float foam_noise = 0.5 + 0.5 * sin(UV.x * 12.0 + TIME * 1.3) * cos(UV.y * 10.0 - TIME * 0.9);
	foam *= mix(0.7, 1.0, foam_noise);
	// Blend foam color over base
	ALBEDO = mix(ALBEDO, foam_color, foam * foam_intensity);

	// Transparency: more opaque at grazing angles, and a small boost where foam appears
	ALPHA = clamp(base_alpha + fresnel_opacity * fres + foam * foam_alpha_boost, 0.0, 1.0);
}
