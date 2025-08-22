package draw

import "engine:utils"

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 5

MAX_TRIANGLES :: 4096
MAX_VERTEX_COUNT ::  MAX_TRIANGLES * 3
MAX_TEXTURES :: 16

WHITE_TEXTURE :: 0

CHAR_COUNT  :: 96
FONT_HEIGHT :: 24

vec2 :: utils.vec2
vec4 :: utils.vec4

ivec2 :: utils.ivec2
ivec4 :: utils.ivec4

Pivot :: utils.Pivot

FONT_DATA :: #load("res/jetbrains_mono.ttf", []u8)
@(rodata) VERTEX_SHADER := #load("res/vertex.glsl", cstring)
@(rodata) FRAGMENT_SHADER := #load("res/fragment.glsl", cstring)
