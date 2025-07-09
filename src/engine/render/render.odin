package render

import "core:math"
import "core:fmt"
import "core:mem"
import "core:os"

import "vendor:glfw"
import gl "vendor:OpenGL"

@(private="file") _render_state : struct {
  vao : u32,
  vbo : u32,
  
  program_id : u32,
  
  triangle_data : [_MAX_VERTEX_COUNT] _RenderVertex,
  triangle_count : u32,

  texture_handles : [_MAX_TEXTURES]_TextureHandle,
  texture_count : u32,
  texture_freelist : ^_TextureHandle,
}

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

  handle.id = 0 // Replace with actual call
  handle.next = nil

  return handle.id
}

unload_texture :: proc(id: u32) {
  for i in 0..<_MAX_TEXTURES {
    texture := &_render_state.texture_handles[i]
    if texture.id != id do continue

    texture.id = 0
    texture.next = _render_state.texture_freelist

    _render_state.texture_freelist = texture
    break
  }
}

init :: proc()
{
  gl.load_up_to(_GL_VERSION_MAJOR, _GL_VERSION_MINOR, glfw.gl_set_proc_address)
  gl.Enable(gl.MULTISAMPLE)

  gl.GenVertexArrays(1, &_render_state.vao)
  gl.BindVertexArray(_render_state.vao)

  gl.GenBuffers(1, &_render_state.vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, _render_state.vbo)
  gl.BufferData(gl.ARRAY_BUFFER, _MAX_VERTEX_COUNT * size_of(_RenderVertex), nil, gl.DYNAMIC_DRAW)

  gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) 0);
  gl.EnableVertexAttribArray(0);

  gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (3 * size_of(f32)));
  gl.EnableVertexAttribArray(1);

  gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (7 * size_of(f32)));
  gl.EnableVertexAttribArray(2);

  gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, size_of(_RenderVertex), cast(uintptr) (9 * size_of(f32)));
  gl.EnableVertexAttribArray(3);

  _render_state.program_id = gl.CreateProgram()

  vtx_shader := gl.CreateShader(gl.VERTEX_SHADER)
  gl.ShaderSource(vtx_shader, 1, &_VERTEX_SHADER_SOURCE, nil)
  gl.CompileShader(vtx_shader)

  frg_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
  gl.ShaderSource(frg_shader, 1, &_FRAGMENT_SHADER_SOURCE, nil)
  gl.CompileShader(frg_shader)


  gl.AttachShader(_render_state.program_id, vtx_shader)
  gl.AttachShader(_render_state.program_id, frg_shader)
  gl.LinkProgram(_render_state.program_id)

  gl.DeleteShader(vtx_shader)
  gl.DeleteShader(frg_shader)
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
  _render_state.triangle_count = 0
}

end_frame :: proc()
{
  gl.BindBuffer(gl.ARRAY_BUFFER, _render_state.vbo)
  gl.BufferSubData(gl.ARRAY_BUFFER, 0, cast(int) _render_state.triangle_count * 3 * size_of(_RenderVertex), &_render_state.triangle_data[0])

  gl.UseProgram(_render_state.program_id)

  gl.BindVertexArray(_render_state.vao)
  gl.DrawArrays(gl.TRIANGLES, 0, cast(i32) _render_state.triangle_count * 3)

}

deinit :: proc()
{
  gl.DeleteBuffers(1, &_render_state.vbo)
  gl.DeleteVertexArrays(1, &_render_state.vao)
  gl.DeleteProgram(_render_state.program_id)
  _render_state = {}
}

set_viewport :: proc(width, height : i32)
{
  gl.Viewport(0, 0, width, height)
}

wireframe_mode :: proc(on : bool) 
{
  gl.PolygonMode(gl.FRONT_AND_BACK, on ? gl.LINE : gl.FILL)
}

/*
- Lowest level primitive drawing API
  mostly every other drawing command 
  is going to be build on this, so the 
  function signature is going to be very verbose
*/
push_triangle :: #force_inline proc(
  v1, v2, v3 : [3]f32, 
  col1, col2, col3 : [4]f32,
  uv1, uv2, uv3 : [2]f32,
  tex_id : u32 = 0
) {
  if _render_state.triangle_count >= _MAX_TRIANGLES {
    end_frame()
    begin_frame()
  }

  _render_state.triangle_data[_render_state.triangle_count * 3 + 0].position = v1
  _render_state.triangle_data[_render_state.triangle_count * 3 + 0].color = col1
  _render_state.triangle_data[_render_state.triangle_count * 3 + 0].tex_coord = uv1
  _render_state.triangle_data[_render_state.triangle_count * 3 + 0].tex_id = cast(f32) tex_id

  _render_state.triangle_data[_render_state.triangle_count * 3 + 1].position = v2
  _render_state.triangle_data[_render_state.triangle_count * 3 + 1].color = col2
  _render_state.triangle_data[_render_state.triangle_count * 3 + 1].tex_coord = uv2
  _render_state.triangle_data[_render_state.triangle_count * 3 + 1].tex_id = cast(f32) tex_id

  _render_state.triangle_data[_render_state.triangle_count * 3 + 2].position = v3
  _render_state.triangle_data[_render_state.triangle_count * 3 + 2].color = col3
  _render_state.triangle_data[_render_state.triangle_count * 3 + 2].tex_coord = uv3
  _render_state.triangle_data[_render_state.triangle_count * 3 + 2].tex_id = cast(f32) tex_id

  _render_state.triangle_count += 1
}

/*
- Rects are axis aligned quads that have their 
  origin at one of their corners

  position : origin of rect
  size : width, height
  color : fill color,
  radii : array of all radii
  segment_length : rough length of each segment
  z_pos : z order
*/
push_rect :: proc (
  position : [2]f32,
  size : [2]f32,
  color : [4]f32,
  radii : [4]f32 = 0,
  segment_length : f32 = 5.0,
  tex_id : u32 = 0,
  texcoords : [4]f32 = {0,0,1,1},
  z_pos : f32 = 0.0,

) {
  half_size := size * 0.5
  max_radius := half_size.x
  adjusted_radii : [4]f32 = radii

  if half_size.y < max_radius { max_radius = half_size.y }
  for i in 0..<4 {
    if radii[i] > max_radius {
      adjusted_radii[i] = max_radius
    }
  }

  corners := [?][2]f32{
    position + {0, adjusted_radii.x},
    position + {size.x - adjusted_radii.y, 0},
    position + {size.x, size.y - adjusted_radii.z},
    position + {adjusted_radii.w, size.y}
  }
  
  @(static, rodata) corner_dirs := [?][2]f32 {
    {1,0}, {0,1}, {-1,0}, {0,-1}
  }

  @(static, rodata) base_angle := [4]f32 {
    math.PI,
    -math.PI * 0.5,
    0.0,
    math.PI * 0.5
  }

  uv_size := texcoords.zw - texcoords.xy

  segments := adjusted_radii * math.PI * 0.5 / segment_length
  total_segments := segments[0] + segments[1] + segments[2] + segments[3]

  for i in 0..<4 {
    radius := adjusted_radii[i]
    if radius <= 0.5 {
      continue
    }

    center := corners[i]
    start_angle := base_angle[i]
    end_angle := start_angle + math.PI * 0.5

    arc_len := radius * (math.PI * 0.5)
    segments := cast(i32)(arc_len / segment_length)
    segments = math.clamp(segments, 1, 16)

    step := (math.PI * 0.5) / f32(segments)

    for j in 1..<segments {
      theta0 := start_angle + step * f32(j)
      theta1 := theta0 + step

      p0 := center - position
      p1 := center + ({math.cos(theta0), math.sin(theta0)} + corner_dirs[i]) * radius - position
      p2 := center + ({math.cos(theta1), math.sin(theta1)} + corner_dirs[i]) * radius - position

      push_triangle(
        {p0.x + position.x, p0.y + position.y, z_pos},
        {p1.x + position.x, p1.y + position.y, z_pos},
        {p2.x + position.x, p2.y + position.y, z_pos},
        color, color, color,
        p0 * uv_size/size + texcoords.xy, p1 * uv_size/size + texcoords.xy, p2 * uv_size/size + texcoords.xy,
        tex_id
      )
    }
  }
  convex_vertices : [8][2]f32 = ---
  _top := 0

  for i in 0..<4 {
    radius := adjusted_radii[i]
    if radius <= 0.5 {
      offset := corner_dirs[i]
      offset = {offset.y, -offset.x}
      convex_vertices[_top] = corners[i] + offset * radius
      _top += 1
      continue
    }

    offset := corner_dirs[i]
    offset += { offset.y, -offset.x }
    offset = offset * radius

    convex_vertices[_top] = corners[i]
    convex_vertices[_top + 1] = corners[i] + offset

    _top += 2
  }

  p0 := convex_vertices[0] - position
  for i in 0..<_top-2 {
    i1 := (i + 1) % _top
    i2 := (i + 2) % _top
    p1 := convex_vertices[i1] - position
    p2 := convex_vertices[i2] - position
    
    push_triangle(
      {p0.x + position.x, p0.y + position.y, 0.0}, 
      {p1.x + position.x, p1.y + position.y, 0.0}, 
      {p2.x + position.x, p2.y + position.y, 0.0},
      color, color, color,
      p0 * uv_size / size + texcoords.xy,p1 * uv_size / size + texcoords.xy,p2 * uv_size / size + texcoords.xy,
      tex_id
    )
  }
}

upload_projection :: proc(camera : ^Camera)
{
  gl.UseProgram(_render_state.program_id)
  proj_loc := gl.GetUniformLocation(_render_state.program_id, "u_proj")
  gl.UniformMatrix4fv(proj_loc, 1, false, &camera.projection[0][0])
}

hex_code_to_4f :: #force_inline proc(hex : HexColor) -> [4]f32
{
  return [4]f32 {cast(f32) hex.r,cast(f32) hex.g,cast(f32) hex.b,cast(f32) hex.a} / 255.0
}

upload_view :: proc(camera : ^Camera)
{
  gl.UseProgram(_render_state.program_id)
  proj_loc := gl.GetUniformLocation(_render_state.program_id, "u_view")
  gl.UniformMatrix4fv(proj_loc, 1, false, &camera.view[0][0])
}

MyUnion :: union {
  f32,
  i32,
  uint,
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
_MAX_VERTEX_COUNT ::  _MAX_TRIANGLES * 3
_MAX_TEXTURES :: 8
_MAX_TRIANGLES :: 4096

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
