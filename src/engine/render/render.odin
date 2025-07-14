package render

import "core:math/rand"
import "core:math/linalg"
import "core:math"
import "core:fmt"
import "core:mem"
import "core:os"

import "vendor:glfw"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"
import stbt "vendor:stb/truetype"

RenderState :: struct {
  vao : u32,
  vbo : u32,
  ebo : u32,
  
  program_id : u32,
  
  vertex_array : [_MAX_VERTEX_COUNT] _RenderVertex,
  vertex_count : u32,
  index_array  : [_MAX_VERTEX_COUNT] u32,
  index_count : u32,

  texture_handles : [_MAX_TEXTURES]_TextureHandle,
  texture_count : u32,
  texture_freelist : ^_TextureHandle,

  coord_space : CoordSpace,
  z_position  : f32,
}
@(private) _render_state : RenderState

load_texture :: proc() -> u32 {
  handle: ^_TextureHandle

  if _render_state.texture_freelist != nil {
    handle = _render_state.texture_freelist
    _render_state.texture_freelist = handle.next
  } else {
    if _render_state.texture_count >= _MAX_TEXTURES {
      return 0
    }
    handle = &_render_state.texture_handles[_render_state.texture_count]
    _render_state.texture_count += 1
  }

  handle.id = 0 // Replace with actual gl call
  handle.next = nil

  offset := cast(uintptr) handle - cast(uintptr) &_render_state.texture_handles[0]
  return cast(u32) (offset / size_of(_TextureHandle))
}

unload_texture :: proc(id: u32) {
  texture := &_render_state.texture_handles[id]
  if texture.id == 0 { return }

  texture.id = 0
  texture.next = _render_state.texture_freelist
  _render_state.texture_freelist = texture
}

init :: proc()
{
  { // OpenglInit
    using gl

    load_up_to(_GL_VERSION_MAJOR, _GL_VERSION_MINOR, glfw.gl_set_proc_address)

    Enable(gl.MULTISAMPLE)
    Enable(gl.DEPTH_TEST)
    DepthFunc(gl.LEQUAL)

    GenVertexArrays(1, &_render_state.vao)
    BindVertexArray(_render_state.vao)

    GenBuffers(1, &_render_state.vbo)
    BindBuffer(gl.ARRAY_BUFFER, _render_state.vbo)
    BufferData(gl.ARRAY_BUFFER, _MAX_VERTEX_COUNT * size_of(_RenderVertex), nil, gl.DYNAMIC_DRAW)

    VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) 0);
    EnableVertexAttribArray(0);

    VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (3 * size_of(f32)));
    EnableVertexAttribArray(1);

    VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (7 * size_of(f32)));
    EnableVertexAttribArray(2);

    VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (9 * size_of(f32)));
    EnableVertexAttribArray(3);

    GenBuffers(1, &_render_state.ebo)
    BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _render_state.ebo)
    BufferData(gl.ELEMENT_ARRAY_BUFFER, _MAX_VERTEX_COUNT * size_of(u32), nil, gl.DYNAMIC_DRAW)


    _render_state.program_id = CreateProgram()

    vtx_shader := gl.CreateShader(gl.VERTEX_SHADER)
    ShaderSource(vtx_shader, 1, &_VERTEX_SHADER_SOURCE, nil)
    CompileShader(vtx_shader)

    frg_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    ShaderSource(frg_shader, 1, &_FRAGMENT_SHADER_SOURCE, nil)
    CompileShader(frg_shader)

    AttachShader(_render_state.program_id, vtx_shader)
    AttachShader(_render_state.program_id, frg_shader)
    LinkProgram(_render_state.program_id)

    DeleteShader(vtx_shader)
    DeleteShader(frg_shader)
  }

  { // Render State Init
    _render_state.coord_space = {
      projection = linalg.identity_matrix(matrix[4,4]f32),
      camera = linalg.identity_matrix(matrix[4,4]f32)
    }
    _render_state.z_position = 0.0
  }

}

clear_frame :: proc(color : HexColor)
{
  gl.ClearColor(
    cast(f32) color.r / 255.0,
    cast(f32) color.g / 255.0,
    cast(f32) color.b / 255.0,
    cast(f32) color.a / 255.0
  )
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

begin_frame :: proc()
{
  _render_state.vertex_count = 0
  _render_state.index_count = 0
}

end_frame :: proc()
{
  gl.BindBuffer(gl.ARRAY_BUFFER, _render_state.vbo)
  gl.BufferSubData(gl.ARRAY_BUFFER, 0, cast(int) _render_state.vertex_count * size_of(_RenderVertex), &_render_state.vertex_array[0])

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _render_state.ebo)
  gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, cast(int) _render_state.index_count * size_of(u32), &_render_state.index_array[0])
  
  gl.UseProgram(_render_state.program_id)

  gl.BindVertexArray(_render_state.vao)
  gl.DrawElements(gl.TRIANGLES, cast(i32) _render_state.index_count, gl.UNSIGNED_INT, nil)
}

deinit :: proc()
{
  gl.DeleteBuffers(1, &_render_state.vbo)
  gl.DeleteVertexArrays(1, &_render_state.vao)
  gl.DeleteProgram(_render_state.program_id)
  _render_state = {}
}

push_triangle :: proc(
  v1, v2, v3 : [2]f32, // position
  c1, c2, c3 : [4]f32, // color 
  u1, u2, u3 : [2]f32, // uv
  tex_id : u32 = 0,
)
{
  v_slots := (_MAX_VERTEX_COUNT - _render_state.vertex_count)
  i_slots := (_MAX_VERTEX_COUNT - _render_state.index_count)

  if v_slots < 3 || i_slots < 3 {
    end_frame()
    begin_frame()
  }

  _render_state.vertex_array[_render_state.vertex_count + 0].position = {v1.x, v1.y, _render_state.z_position}
  _render_state.vertex_array[_render_state.vertex_count + 1].position = {v2.x, v2.y, _render_state.z_position}
  _render_state.vertex_array[_render_state.vertex_count + 2].position = {v3.x, v3.y, _render_state.z_position}

  _render_state.vertex_array[_render_state.vertex_count + 0].color = c1
  _render_state.vertex_array[_render_state.vertex_count + 1].color = c2
  _render_state.vertex_array[_render_state.vertex_count + 2].color = c3
  
  _render_state.vertex_array[_render_state.vertex_count + 0].tex_coord = u1
  _render_state.vertex_array[_render_state.vertex_count + 1].tex_coord = u2
  _render_state.vertex_array[_render_state.vertex_count + 2].tex_coord = u3

  _render_state.vertex_array[_render_state.vertex_count + 0].tex_id = cast(f32) tex_id
  _render_state.vertex_array[_render_state.vertex_count + 1].tex_id = cast(f32) tex_id
  _render_state.vertex_array[_render_state.vertex_count + 2].tex_id = cast(f32) tex_id

  _render_state.index_array[_render_state.index_count + 0] = _render_state.vertex_count + 0
  _render_state.index_array[_render_state.index_count + 1] = _render_state.vertex_count + 1
  _render_state.index_array[_render_state.index_count + 2] = _render_state.vertex_count + 2

  _render_state.index_count += 3
  _render_state.vertex_count += 3
}

push_rect :: proc(
  pos, size : [2]f32,
  color : [4]f32,
  uv : [4]f32 = {0, 0, 1, 1},
  z_pos : f32 = 0.0,
  tex_id : u32 = 0,
){
  v_slots := (_MAX_VERTEX_COUNT - _render_state.vertex_count)
  i_slots := (_MAX_VERTEX_COUNT - _render_state.index_count)

  if v_slots < 4 || i_slots < 6 {
    end_frame()
    begin_frame()
  }

  corners := [4][2]f32 {
    pos,                // top left 
    pos + {size.x, 0},  // top right
    pos + size,         // bottom right
    pos + {0, size.y}   // bottom left
  }

  tex_coords := [4][2]f32 {
    uv.xy, uv.zy, uv.zw, uv.xw
  }

  for i in 0..<4 {
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].position  = {corners[i].x, corners[i].y, _render_state.z_position}
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].color     = color
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].tex_coord = tex_coords[i]
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].tex_id    = cast(f32) tex_id
  }

  _render_state.index_array[_render_state.index_count + 0] = _render_state.vertex_count + 0
  _render_state.index_array[_render_state.index_count + 1] = _render_state.vertex_count + 2
  _render_state.index_array[_render_state.index_count + 2] = _render_state.vertex_count + 1
  _render_state.index_array[_render_state.index_count + 3] = _render_state.vertex_count + 0
  _render_state.index_array[_render_state.index_count + 4] = _render_state.vertex_count + 3
  _render_state.index_array[_render_state.index_count + 5] = _render_state.vertex_count + 2
  
  _render_state.vertex_count += 4
  _render_state.index_count += 6
}

set_viewport :: proc(width, height : i32)
{
  gl.Viewport(0, 0, width, height)
}

wireframe_mode :: proc(on : bool) 
{
  gl.PolygonMode(gl.FRONT_AND_BACK, on ? gl.LINE : gl.FILL)
  if on {
    gl.Disable(gl.MULTISAMPLE)
  }else {
    gl.Enable(gl.MULTISAMPLE)
  }
}


linear :: #force_inline proc(hexcode : u32) -> [4]f32
{
  hex := HexColor {hexcode = hexcode}
  return [4]f32 {cast(f32) hex.r,cast(f32) hex.g,cast(f32) hex.b,cast(f32) hex.a} / 255.0
}

upload_projection :: proc(coord : ^CoordSpace)
{
  gl.UseProgram(_render_state.program_id)
  proj_loc := gl.GetUniformLocation(_render_state.program_id, "u_proj")
  gl.UniformMatrix4fv(proj_loc, 1, false, &coord.projection[0][0])
}

upload_view :: proc(coord : ^CoordSpace)
{
  gl.UseProgram(_render_state.program_id)
  proj_loc := gl.GetUniformLocation(_render_state.program_id, "u_view")
  gl.UniformMatrix4fv(proj_loc, 1, false, &coord.camera[0][0])
}

HexColor :: struct #raw_union { // 0xRRGGBBAA
  hexcode : u32,
  using channels : struct {
  a : u8,
  b : u8,
  g : u8,
  r : u8,
  },
}

_GL_VERSION_MAJOR :: 4
_GL_VERSION_MINOR :: 5

_MAX_TEXTURES :: 8
_MAX_TRIANGLES :: 4096
_MAX_VERTEX_COUNT ::  _MAX_TRIANGLES * 3

_RenderVertex :: struct {
  position : [3]f32,
  color    : [4]f32, // (r, g, b, a)
  tex_coord: [2]f32, 
  tex_id   : f32,    // cast texture_id -> float
}

_TextureHandle :: struct {
  next : ^_TextureHandle, 
  id   : u32,
}

@(rodata) _VERTEX_SHADER_SOURCE := cast(cstring) `#version 450 core
layout (location=0) in vec3 aPos;
layout (location=1) in vec4 aColor;
layout (location=2) in vec2 aTexCoords;
layout (location=3) in float aTexId;
uniform mat4 u_proj;
uniform mat4 u_view;
out vec4 f_color;
out int f_texid;
out vec2 f_texcoords;
void main() {
  f_color = aColor;
  f_texcoords = aTexCoords;
  f_texid = int(aTexId);
  gl_Position = u_proj * u_view * vec4(aPos, 1.0);
}`

@(rodata)_FRAGMENT_SHADER_SOURCE := cast(cstring) `#version 450 core
in vec4 f_color;
in vec2 f_texcoords;
in int f_texid;
out vec4 FragColor;
uniform sampler2D u_texslots[8];
void main() {
  FragColor = f_color;
}`

_FONT_ATLAS_WIDTH :: 256
_FONT_ATLAS_HEIGHT :: 256
_CHAR_COUNT :: 96
Font :: struct {
  char_data : [_CHAR_COUNT]stbt.bakedchar,
  tex_id : u32,
}
_font : Font

load_font :: proc() 
{
  using stbt

  bitmap, _ := mem.alloc(_FONT_ATLAS_WIDTH * _FONT_ATLAS_HEIGHT)
  font_height := 7 * 5 // for some reason this only bakes properly at 15 ? it's a 16px font dou...
  path := "res/fonts/minecraft.ttf" // #user
  ttf_data, err := os.read_entire_file(path)
  assert(ttf_data != nil, "failed to read font")

  ret := BakeFontBitmap(raw_data(ttf_data), 0, auto_cast font_height, auto_cast bitmap, _FONT_ATLAS_WIDTH, _FONT_ATLAS_HEIGHT, 32, _CHAR_COUNT, &_font.char_data[0])
  assert(ret > 0, "not enough space in bitmap")
  stbi.write_png("font.png", auto_cast _FONT_ATLAS_WIDTH, auto_cast _FONT_ATLAS_HEIGHT, 1, bitmap, auto_cast _FONT_ATLAS_WIDTH)
}
