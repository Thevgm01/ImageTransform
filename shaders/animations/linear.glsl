#version 430
uniform float time;
uniform sampler2D mapImage;

struct Particle {
	vec2 pos;
};

layout(std430, binding = 0) buffer particlesBuffer
{
	Particle particles[];
};

layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in;

void main()
{
	uint i = gl_GlobalInvocationID.x;

    particles[i].pos = vec2(gl_GlobalInvocationID.x + 100 * time, gl_GlobalInvocationID.y);
}
