package draw

import "engine:utils"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5

MAX_TRIANGLES :: 4096
MAX_VERTEX_COUNT ::  MAX_TRIANGLES * 3

MAX_TEXTURES :: 16

WHITE_TEXTURE :: 0

vec2 :: utils.vec2
vec4 :: utils.vec4

ivec2 :: utils.ivec2
ivec4 :: utils.ivec4

Pivot :: utils.Pivot


@(rodata) VERTEX_SHADER := cast(cstring) `#version 450 core
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
}`

@(rodata) FRAGMENT_SHADER := cast(cstring) `#version 450 core
in VS_OUT {
    vec2 position;
    vec4 color;
    vec2 texcoords;
    float tex_id;
} fs_in;

out vec4 frag_color;

uniform sampler2D u_texslots[16];

void main() {
    int tex_id = int(fs_in.tex_id);
    vec4 sampled_texture = texture(u_texslots[tex_id], fs_in.texcoords);
    frag_color = fs_in.color * sampled_texture;
}`
