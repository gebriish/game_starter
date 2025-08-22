#version 450 core
layout (location = 0) in vec2  a_pos;
layout (location = 1) in vec4  a_color;
layout (location = 2) in vec2  a_uv;
layout (location = 3) in float a_tex_id;

out VS_OUT {
  vec2 position;
  vec4 color;
  vec2 texcoords;
  float tex_id;
} vs_out;

uniform mat4 u_view;
uniform mat4 u_proj;

void main() {
  vs_out.position = a_pos;
  vs_out.color = a_color;
  vs_out.texcoords = a_uv;
  vs_out.tex_id = a_tex_id;
  gl_Position = u_proj * u_view * vec4(a_pos, 0.0, 1.0);
}
