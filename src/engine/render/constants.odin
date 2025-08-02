package render

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5

MAX_TEXTURES :: 8
MAX_TRIANGLES :: 4096
MAX_VERTEX_COUNT ::  MAX_TRIANGLES * 3

FONT_PATH :: "res/font_bitmap.png"

WHITE_TEXTURE :: 0
FONT_TEXTURE :: 1

CIRCLE_COORD_INSIDE :: 128
BEZIER_COORD_INSIDE :: 128

BEZIER_COORD_P1 :: [2]u8 {0, 0}
BEZIER_COORD_P2 :: [2]u8 {128, 0}
BEZIER_COORD_P3 :: [2]u8 {255, 255}

FONT_ATLAS_DIM :: [2]u32 {16, 8} // Number of glyphs in (columns, rows)
FONT_TEXTURE_SIZE :: [2]u32 {96, 96} // Actual texture pixel dimensions

GLYPH_SIZE :: [2]f32 {
  f32(FONT_TEXTURE_SIZE.x) / f32(FONT_ATLAS_DIM.x),
  f32(FONT_TEXTURE_SIZE.y) / f32(FONT_ATLAS_DIM.y),
}
UV_PER_GLYPH :: [2]f32 {
  1.0 / f32(FONT_ATLAS_DIM.x),
  1.0 / f32(FONT_ATLAS_DIM.y),
}
GLYPH_TRIM :: [4]f32 {1,1,0,1}

PX_PER_UV :: [2]f32{
  1.0 / f32(FONT_TEXTURE_SIZE.x),
  1.0 / f32(FONT_TEXTURE_SIZE.y),
}

@(rodata) _VERTEX_SHADER_SOURCE := cast(cstring) `#version 450 core
layout (location=0) in vec3 aPos;
layout (location=1) in vec4 aColor;
layout (location=2) in vec2 aTexCoords;
layout (location=3) in float aTexId;
layout (location=4) in vec4 aMaskCoords;
uniform mat4 u_proj;
uniform mat4 u_view;
out vec4 f_color;
out float f_texid;
out vec2 f_texcoords;
out vec2 f_circcoords;
out vec2 f_bezrcoords;
void main() {
  f_color = aColor;
  f_texcoords = aTexCoords;
  f_texid = aTexId;
  f_circcoords = aMaskCoords.xy;
  f_bezrcoords = aMaskCoords.zw;
  gl_Position = u_proj * u_view * vec4(aPos, 1.0);
}`

@(rodata)_FRAGMENT_SHADER_SOURCE := cast(cstring) `#version 450 core
in vec4 f_color;
in vec2 f_texcoords;
in float f_texid;
in vec2 f_circcoords;
in vec2 f_bezrcoords;

out vec4 FragColor;

uniform sampler2D u_texslots[8];
uniform int u_wireframe;

void main() {
  if (u_wireframe >= 1) { FragColor = vec4(0.470588, 0.749019, 0.286274, 1.0); return; }

  int texid = int(f_texid);

  vec4 final_color = f_color * texture(u_texslots[texid], f_texcoords);

  float face_scalar = gl_FrontFacing ? 1.0 : -1.0;
  
  vec2 centered_coords = f_circcoords * 2.0 - 1.0;
  float dist = length(centered_coords) - 1.0;

  float edge_width = fwidth(dist) * 0.5 * face_scalar;
  float alpha = smoothstep(edge_width, -edge_width, dist);

  if (alpha <= 0.0) discard;

  float mask = f_bezrcoords.x * f_bezrcoords.x - f_bezrcoords.y;
  mask *= face_scalar;
  edge_width = fwidth(mask) * 0.5;
  alpha *= smoothstep(edge_width, -edge_width, mask);
  final_color.a *= alpha;
  if (final_color.a <= 0.0) { discard; }
  FragColor = final_color;
}`
