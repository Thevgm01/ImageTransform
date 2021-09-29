#version 400 core

layout(location = 0) out vec4 out_color;

uniform vec2 resolution;
in vec4 color;
 
void main(void)
{
	vec2 uv = gl_FragCoord.xy / resolution.xy;

	//out_color = color;
    out_color = vec4(1, 1, 1, 1);
}