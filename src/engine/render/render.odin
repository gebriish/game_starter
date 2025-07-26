package render

import "core:math/linalg"
import "core:math"
import "core:fmt"
import "core:os"

import "vendor:glfw"
import gl "vendor:OpenGL"

import stbi "vendor:stb/image"
import stbtt "vendor:stb/truetype"

HexColor :: struct #raw_union { // 0xRRGGBBAA
  hexcode : u32be,
  using channels : struct {
    r : u8,
    g : u8,
    b : u8,
    a : u8,
  },
}

_RenderVertex :: struct {
  position : [3]f32,
  color    : [4]f32,
  tex_coord: [2]f32, 
  tex_id   : f32,
  circle_coord : [2]u8,
  bezier_coord : [2]u8,
}

_TextureHandle :: struct {
  next : ^_TextureHandle, 
  id   : u32,
}

_render_state : RenderState
RenderState :: struct {
  vao : u32,
  vbo : u32,
  ebo : u32,

  main_shader : u32,
  main_shader_uniforms : gl.Uniforms,


  vertex_array : [MAX_VERTEX_COUNT] _RenderVertex,
  vertex_count : u32,
  index_array  : [MAX_VERTEX_COUNT] u32,
  index_count : u32,

  texture_handles : [MAX_TEXTURES]_TextureHandle,
  texture_count : u32,
  texture_freelist : ^_TextureHandle,

  coord_space : CoordSpace,
  z_position  : f32,
}

Texture :: struct {
  data     : rawptr,
  width    : i32,
  height   : i32,
  channels : i32,
}

load_font :: proc()
{
  width, height, channels : i32
  bitmap := stbi.load(FONT_PATH, &width, &height, &channels, 0)

  upload_texture({
    data = bitmap,
    width = width,
    height = height,
    channels = channels
  })

  stbi.image_free(bitmap)
}

upload_texture :: proc(texture: Texture) -> u32 
{
  if texture.data == nil || texture.width <= 0 || texture.height <= 0 || texture.channels < 1 || texture.channels > 4 {
    fmt.eprintln("render::upload_texture: Invalid texture input")
    return 0
  }

  handle: ^_TextureHandle
  if _render_state.texture_freelist != nil {
    handle = _render_state.texture_freelist
    _render_state.texture_freelist = handle.next
  } else {
    if _render_state.texture_count >= MAX_TEXTURES {
      fmt.eprintln("render::upload_texture: Maximum texture limit reached")
      return 0
    }
    handle = &_render_state.texture_handles[_render_state.texture_count]
    _render_state.texture_count += 1
  }

  offset := cast(uintptr) handle - cast(uintptr) &_render_state.texture_handles[0]
  texture_index := cast(u32) (offset / size_of(_TextureHandle))

  gl.GenTextures(1, &handle.id)
  handle.next = nil

  internal_format: i32
  format         : u32

  switch texture.channels {
  case 1:
    internal_format = gl.RED
    format          = gl.RED
  case 2:
    internal_format = gl.RG
    format          = gl.RG
  case 3:
    internal_format = gl.RGB
    format          = gl.RGB
  case 4:
    internal_format = gl.RGBA
    format          = gl.RGBA
  case:
    fmt.eprintln("render::upload_texture(...) -> Unsupported channel count")
    return 0
  }

  gl.ActiveTexture(gl.TEXTURE0 + texture_index)
  gl.BindTexture(gl.TEXTURE_2D, handle.id)

  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

  gl.TexImage2D(
    gl.TEXTURE_2D,
    0,
    internal_format,
    texture.width,
    texture.height,
    0,
    format,
    gl.UNSIGNED_BYTE,
    texture.data,
  )
  return texture_index
}

unload_texture :: proc(id: u32) {
  texture := &_render_state.texture_handles[id]
  if texture.id == 0 { return }

  gl.DeleteTextures(1, &texture.id)

  texture.id = 0
  texture.next = _render_state.texture_freelist
  _render_state.texture_freelist = texture
}


init :: proc()
{
  { // OpenglInit
    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)

    gl.Enable(gl.MULTISAMPLE)
    gl.Enable(gl.DEPTH_TEST)
    gl.Enable(gl.BLEND)

    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.DepthFunc(gl.LEQUAL)

    gl.GenVertexArrays(1, &_render_state.vao)
    gl.BindVertexArray(_render_state.vao)

    gl.GenBuffers(1, &_render_state.vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, _render_state.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, MAX_VERTEX_COUNT * size_of(_RenderVertex), nil, gl.DYNAMIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) 0);
    gl.EnableVertexAttribArray(0);

    gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (3 * size_of(f32)));
    gl.EnableVertexAttribArray(1);

    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (7 * size_of(f32)));
    gl.EnableVertexAttribArray(2);

    gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (9 * size_of(f32)));
    gl.EnableVertexAttribArray(3);

    gl.VertexAttribPointer(4, 4, gl.UNSIGNED_BYTE, gl.TRUE, size_of(_RenderVertex), cast(uintptr) (10 * size_of(f32)));
    gl.EnableVertexAttribArray(4);

    gl.GenBuffers(1, &_render_state.ebo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _render_state.ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, MAX_VERTEX_COUNT * size_of(u32), nil, gl.DYNAMIC_DRAW)

    _render_state.main_shader = gl.CreateProgram()

    vtx_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vtx_shader, 1, &_VERTEX_SHADER_SOURCE, nil)
    gl.CompileShader(vtx_shader)

    frg_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(frg_shader, 1, &_FRAGMENT_SHADER_SOURCE, nil)
    gl.CompileShader(frg_shader)

    gl.AttachShader(_render_state.main_shader, vtx_shader)
    gl.AttachShader(_render_state.main_shader, frg_shader)
    gl.LinkProgram(_render_state.main_shader)

    gl.UseProgram(_render_state.main_shader)
    defer {
      gl.DeleteShader(vtx_shader)
      gl.DeleteShader(frg_shader)
      gl.UseProgram(0)
    }

    _render_state.main_shader_uniforms = gl.get_uniforms_from_program(_render_state.main_shader)

    samplers := [MAX_TEXTURES]i32 {}
    for i in 0..<MAX_TEXTURES {
      samplers[i] = cast(i32) i
    }


    gl.Uniform1iv(gl.GetUniformLocation(_render_state.main_shader, "u_texslots"), MAX_TEXTURES, &samplers[0])
  }

  { // Render State Init
    _render_state.coord_space = {
      projection = linalg.identity_matrix(matrix[4,4]f32),
      camera = linalg.identity_matrix(matrix[4,4]f32)
    }
    _render_state.z_position = 0.0

    white_texture := [4]u8 {0xff, 0xff, 0xff, 0xff}
    upload_texture({
      &white_texture[0],
      1,1,
      4,
    })
    load_font()
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

_begin_frame :: proc()
{
  _render_state.vertex_count = 0
  _render_state.index_count = 0
}

_end_and_begin_frame :: #force_inline proc() {
  _end_frame()
  _begin_frame()
}

_end_frame :: proc()
{
  gl.BindBuffer(gl.ARRAY_BUFFER, _render_state.vbo)
  gl.BufferSubData(gl.ARRAY_BUFFER, 0, cast(int) _render_state.vertex_count * size_of(_RenderVertex), &_render_state.vertex_array[0])

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, _render_state.ebo)
  gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, cast(int) _render_state.index_count * size_of(u32), &_render_state.index_array[0])

  gl.UseProgram(_render_state.main_shader)

  gl.BindVertexArray(_render_state.vao)
  gl.DrawElements(gl.TRIANGLES, cast(i32) _render_state.index_count, gl.UNSIGNED_INT, nil)
}

deinit :: proc()
{
  gl.DeleteBuffers(1, &_render_state.vbo)
  gl.DeleteVertexArrays(1, &_render_state.vao)
  gl.DeleteProgram(_render_state.main_shader)
  _render_state = {}
}

push_triangle :: proc(
  v1, v2, v3 : [2]f32, // position
  c1, c2, c3 : [4]f32, // color 
  u1, u2, u3 : [2]f32, // uv
  tex_id : u32 = 0, // texture index
  cir1: [2]u8 = CIRCLE_COORD_INSIDE, cir2: [2]u8 = CIRCLE_COORD_INSIDE, cir3 : [2]u8 = CIRCLE_COORD_INSIDE, // circle coordinates
  bez1: [2]u8 = BEZIER_COORD_INSIDE, bez2: [2]u8 = BEZIER_COORD_INSIDE, bez3 : [2]u8 = BEZIER_COORD_INSIDE, // bezier curve coordinates
)
{
  v_slots := (MAX_VERTEX_COUNT - _render_state.vertex_count)
  i_slots := (MAX_VERTEX_COUNT - _render_state.index_count)

  if v_slots < 3 || i_slots < 3 {
    _end_and_begin_frame()
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

  _render_state.vertex_array[_render_state.vertex_count + 0].circle_coord = cir1
  _render_state.vertex_array[_render_state.vertex_count + 1].circle_coord = cir2
  _render_state.vertex_array[_render_state.vertex_count + 2].circle_coord = cir3

  _render_state.vertex_array[_render_state.vertex_count + 0].bezier_coord = bez1
  _render_state.vertex_array[_render_state.vertex_count + 1].bezier_coord = bez2
  _render_state.vertex_array[_render_state.vertex_count + 2].bezier_coord = bez3

  _render_state.index_array[_render_state.index_count + 0] = _render_state.vertex_count + 0
  _render_state.index_array[_render_state.index_count + 1] = _render_state.vertex_count + 1
  _render_state.index_array[_render_state.index_count + 2] = _render_state.vertex_count + 2


  _render_state.index_count += 3
  _render_state.vertex_count += 3
}

push_rect_rounded :: proc(
  pos, size : [2]f32,
  color : [4]f32 = 1.0,
  radii : [4]f32 = 10.0,
  tex_id : u32 = 0,
  uv : [4]f32 = {0,0,1,1},
) {
  if size.x <= 0.0 || size.y <= 0.0 { return }
  
  adjusted_radii := radii

  adjust_side :: #force_inline proc(s1, s2 : ^f32, max : f32) {
    side_sum := s1^ + s2^
    if side_sum > max {
      s1^ *= max / side_sum
      s2^ *= max / side_sum
    }
  }
  
  adjust_side(&adjusted_radii[0], &adjusted_radii[1], size.x)
  adjust_side(&adjusted_radii[2], &adjusted_radii[3], size.x)
  adjust_side(&adjusted_radii[2], &adjusted_radii[1], size.y)
  adjust_side(&adjusted_radii[0], &adjusted_radii[3], size.y)

  chopped_corners := [8][2]f32 {}
  num_corners := 0

  corners := [?][2]f32 {
    pos,
    pos + {size.x, 0},
    pos + size,
    pos + {0, size.y},
  }

  @(static, rodata) clock_wise := [?][2]f32 {
    {1.0, 0.0}, {0.0, 1.0}, {-1.0, 0.0}, {0.0, -1.0}
  }

  @(static, rodata) anti_clockwise := [?][2]f32 {
    {0.0, 1.0}, {-1.0, 0.0}, {0.0, -1.0}, {1.0, 0.0}
  }

  vertex_positions : [12][2]f32
  num_vertices := u32(0)
  
  for i in 0..<4 {
    radius := adjusted_radii[i]
    corner := corners[i]

    if radius <= 0.5 {
      vertex_positions[num_vertices] = corner
      num_vertices += 1
    } else {
      vertex_positions[num_vertices]   = corner + anti_clockwise[i] * radius
      vertex_positions[num_vertices+1] = corner + clock_wise[i] * radius
      num_vertices += 2
    }
  }

  v_slots := (MAX_VERTEX_COUNT - _render_state.vertex_count)
  i_slots := (MAX_VERTEX_COUNT - _render_state.index_count)

  if v_slots < num_vertices || i_slots < (num_vertices - 2) * 3 {
    _end_and_begin_frame()
  }
  
  base_index := _render_state.vertex_count

  for i in 0..<num_vertices {
    v := &_render_state.vertex_array[base_index + u32(i)]
  
    local_pos := vertex_positions[i] - pos
    local_uv := local_pos / size

    v.position = {vertex_positions[i].x, vertex_positions[i].y, _render_state.z_position}
    v.color = color
    v.tex_coord = local_uv * (uv.zw - uv.xy) + uv.xy
    v.tex_id = f32(tex_id)
    v.circle_coord = CIRCLE_COORD_INSIDE
    v.bezier_coord = BEZIER_COORD_INSIDE
  }

  for i in 1..<num_vertices - 1 {
    _render_state.index_array[_render_state.index_count + (i - 1) * 3 + 0] = base_index
    _render_state.index_array[_render_state.index_count + (i - 1) * 3 + 1] = base_index + u32(i + 1)
    _render_state.index_array[_render_state.index_count + (i - 1) * 3 + 2] = base_index + u32(i)
  }

  _render_state.vertex_count += num_vertices
  _render_state.index_count += (num_vertices - 2) * 3


  for i in 0..<4 {
    radius := adjusted_radii[i]
    corner := corners[i]

    if radius <= 0.5 { continue }

    p1, p2, p3 := corner, corner + anti_clockwise[i] * radius, corner + clock_wise[i] * radius
    
  
    push_triangle( 
      p1, p2, p3,
      color, color, color,
      (p1 - pos) / size * (uv.zw - uv.xy) + uv.xy, (p2 - pos) / size * (uv.zw - uv.xy) + uv.xy, (p3 - pos) / size * (uv.zw - uv.xy) + uv.xy,
      tex_id,
      0, {CIRCLE_COORD_INSIDE, 0},{0, CIRCLE_COORD_INSIDE}
    )
  }
}

push_rect :: proc(
  pos, size : [2]f32,
  color : [4]f32 = 1.0,
  uv : [4]f32 = {0, 0, 1, 1},
  tex_id : u32 = 0,
  offset : [2]f32 = 0,
  rotation : f32 = 0,
) {
  v_slots := (MAX_VERTEX_COUNT - _render_state.vertex_count)
  i_slots := (MAX_VERTEX_COUNT - _render_state.index_count)

  if v_slots < 4 || i_slots < 6 {
    _end_and_begin_frame()
  }

  sin_val :f32= math.sin(rotation)
  cos_val :f32= math.cos(rotation)

  rotation_matrix := matrix[2,2]f32 {
  cos_val, -sin_val,
  sin_val, cos_val
  }

  corners := [4][2]f32 {
    rotation_matrix * -offset,
    rotation_matrix * ([2]f32{size.x, 0} - offset),
    rotation_matrix * (size - offset),
    rotation_matrix * ([2]f32{0, size.y} - offset),
  }

  tex_coords := [4][2]f32 {
    uv.xy, uv.zy, uv.zw, uv.xw
  }

  for i in 0..<4 {
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].position  = {corners[i].x + pos.x, corners[i].y + pos.y, _render_state.z_position}
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].color     = color
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].tex_coord = tex_coords[i]
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].tex_id    = cast(f32) tex_id
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].circle_coord = CIRCLE_COORD_INSIDE
    _render_state.vertex_array[_render_state.vertex_count + cast(u32) i].bezier_coord = BEZIER_COORD_INSIDE
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

push_glyph :: proc(

) {

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

  gl.UseProgram(_render_state.main_shader);
  gl.Uniform1i(_render_state.main_shader_uniforms["u_wireframe"].location, on ? 1 : 0)
}


linear :: #force_inline proc(hexcode : u32be) -> [4]f32
{
  hex := HexColor {hexcode = hexcode}
  return [4]f32 {cast(f32) hex.r,cast(f32) hex.g,cast(f32) hex.b,cast(f32) hex.a} / 255.0
}

upload_projection :: proc(coord : ^CoordSpace)
{
  gl.UseProgram(_render_state.main_shader)
  proj_loc := gl.GetUniformLocation(_render_state.main_shader, "u_proj")
  gl.UniformMatrix4fv(proj_loc, 1, false, &coord.projection[0][0])
}

upload_view :: proc(coord : ^CoordSpace)
{
  gl.UseProgram(_render_state.main_shader)
  proj_loc := gl.GetUniformLocation(_render_state.main_shader, "u_view")
  gl.UniformMatrix4fv(proj_loc, 1, false, &coord.camera[0][0])
}

