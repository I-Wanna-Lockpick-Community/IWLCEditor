shader_type canvas_item;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// https://github.com/hughsk/glsl-hsv2rgb
vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 base = COLOR;
	vec2 uv = UV;
	float hue = rand(uv+vec2(TIME,0));
	float sat = rand(uv+vec2(0,TIME));
	COLOR = vec4(hsv2rgb(vec3(hue,sat*base.r,base.g)),base.a);
}