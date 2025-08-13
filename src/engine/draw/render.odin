package draw

import "core:mem"
import "core:math/linalg"
import "core:math"
import "core:fmt"
import "core:os"

import "engine:utils"

import gl "vendor:OpenGL"
import tt "vendor:stb/truetype"

render_state : RenderState
RenderState :: struct {
  vao : u32,
  vbo : u32,
  ibo : u32,

  shader : u32,
  using _shader_data : struct {
    proj_loc, view_loc, tex_slots_loc: i32,
  },

  vertices : [MAX_VERTEX_COUNT] RenderVertex,
  indices  : [MAX_VERTEX_COUNT] u32,
  vertex_count : u32,
  index_count  : u32,

  texture_slots : [MAX_TEXTURES]TextureHandle,
  num_textures : u32,
  texture_freelist : u32,
  active_pass : RenderPass,
  font_atlas : DynamicFontAtlas,
}

RenderVertex :: struct {
  position : vec2,
  color    : vec4,
  uv       : vec2, // 0-1
  tex_id   : f32,
}

CoordSpace :: struct {
  proj,
  view,
  inverse : matrix[4,4]f32,
}

TextureHandle :: struct {
  id : u32, // opengl id, not internal
  next : u32, // freelist pointer to next ~INTERNAL ID~
}

Texture :: struct {
  data : rawptr,
  width : i32,
  height : i32,
  channels : i32,
}

TextureType :: enum {
  Normal,
  Font,
}

RenderPass :: struct {
  draw_type : DrawType,
  coord_space : CoordSpace,
}

DrawType :: enum {
  Triangle,
  Line,
}

Font :: struct {
	char_data: [CHAR_COUNT]tt.bakedchar,
  image : Texture,
}
font : Font

upload_texture :: proc(texture: Texture, type := TextureType.Normal) -> u32 {
  if texture.data == nil || texture.width <= 0 || texture.height <= 0 || texture.channels < 1 || texture.channels > 4 {
    fmt.eprintln("render::upload_texture: Invalid texture input")
    return WHITE_TEXTURE
  }

  result_idx: u32
  
  if render_state.texture_freelist != 0 {
    result_idx = render_state.texture_freelist
    handle := &render_state.texture_slots[result_idx]
    render_state.texture_freelist = handle.next
  } else {
    result_idx = render_state.num_textures
    if result_idx >= MAX_TEXTURES { 
      fmt.eprintln("render::upload_texture: ran out of texture slots")
      return WHITE_TEXTURE
    }
    render_state.num_textures += 1
  }
  
  handle := &render_state.texture_slots[result_idx]
  handle^ = {}
  
  gl.GenTextures(1, &handle.id)
  
  internal_format: i32
  format: u32
  switch texture.channels {
  case 1:
    internal_format = gl.RED
    format = gl.RED
  case 2:
    internal_format = gl.RG
    format = gl.RG
  case 3:
    internal_format = gl.RGB
    format = gl.RGB
  case 4:
    internal_format = gl.RGBA
    format = gl.RGBA
  case:
    fmt.eprintln("render::upload_texture: Unsupported channel count")
    handle.id = 0
    handle.next = render_state.texture_freelist
    render_state.texture_freelist = result_idx
    return WHITE_TEXTURE
  }
  
  gl.ActiveTexture(gl.TEXTURE0 + result_idx)
  gl.BindTexture(gl.TEXTURE_2D, handle.id)
  
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, type == .Normal ? gl.NEAREST : gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, type == .Normal ? gl.NEAREST : gl.LINEAR)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
  gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

  if type == .Font && texture.channels == 1 {
    swizzle := [4]i32{gl.ONE, gl.ONE, gl.ONE, gl.RED}
    gl.TexParameteriv(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_RGBA, &swizzle[0])
  }
  
  gl.TexImage2D(
    gl.TEXTURE_2D,
    0, // level
    internal_format,
    texture.width,
    texture.height,
    0, // border
    format,
    gl.UNSIGNED_BYTE,
    texture.data,
  )
  
  return result_idx
}

free_texture :: proc(texture_id: u32) -> bool {
  if texture_id == WHITE_TEXTURE {
    fmt.eprintln("render::free_texture: Cannot delete WHITE_TEXTURE")
    return false
  }

  if texture_id >= render_state.num_textures {
    fmt.eprintln("render::free_texture: Invalid texture ID")
    return false
  }

  handle := &render_state.texture_slots[texture_id]

  if handle.id == 0 {
    fmt.eprintln("render::free_texture: Texture already freed")
    return false
  }

  gl.DeleteTextures(1, &handle.id)

  handle.id = 0
  handle.next = render_state.texture_freelist
  render_state.texture_freelist = texture_id

  return true
}

render_init :: proc(set_proc_addr : gl.Set_Proc_Address_Type) {
  gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, set_proc_addr)

  gl.Enable(gl.DEPTH_TEST)
  gl.Enable(gl.BLEND)

  gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
  gl.DepthFunc(gl.LEQUAL)

  gl.GenVertexArrays(1, &render_state.vao)
  gl.BindVertexArray(render_state.vao)

  gl.GenBuffers(1, &render_state.vbo)
  gl.BindBuffer(gl.ARRAY_BUFFER, render_state.vbo)
  gl.BufferData(gl.ARRAY_BUFFER, MAX_VERTEX_COUNT * size_of(RenderVertex), nil, gl.DYNAMIC_DRAW)

  gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(RenderVertex), cast(uintptr) 0);
  gl.EnableVertexAttribArray(0);

  gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, size_of(RenderVertex), cast(uintptr) (2 * size_of(f32)));
  gl.EnableVertexAttribArray(1);

  gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(RenderVertex), cast(uintptr) (6 * size_of(f32)));
  gl.EnableVertexAttribArray(2);

  gl.VertexAttribPointer(3, 1, gl.FLOAT, gl.FALSE, size_of(RenderVertex), cast(uintptr) (8 * size_of(f32)));
  gl.EnableVertexAttribArray(3);

  gl.GenBuffers(1, &render_state.ibo)
  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, render_state.ibo)
  gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, MAX_VERTEX_COUNT * size_of(u32), nil, gl.DYNAMIC_DRAW)

  render_state.shader = gl.CreateProgram()

  vtx_shader := gl.CreateShader(gl.VERTEX_SHADER)
  defer gl.DeleteShader(vtx_shader)
  gl.ShaderSource(vtx_shader, 1, &VERTEX_SHADER, nil)
  gl.CompileShader(vtx_shader)

  frg_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
  defer gl.DeleteShader(frg_shader)
  gl.ShaderSource(frg_shader, 1, &FRAGMENT_SHADER, nil)
  gl.CompileShader(frg_shader)

  gl.AttachShader(render_state.shader, vtx_shader)
  gl.AttachShader(render_state.shader, frg_shader)
  gl.LinkProgram(render_state.shader)

  gl.UseProgram(render_state.shader)
  render_state.view_loc = gl.GetUniformLocation(render_state.shader, "u_view")
  render_state.proj_loc = gl.GetUniformLocation(render_state.shader, "u_proj")
  render_state.tex_slots_loc = gl.GetUniformLocation(render_state.shader, "u_texslots")


  samplers := [MAX_TEXTURES]i32 {}
  for i in 0..<MAX_TEXTURES {
    samplers[i] = cast(i32) i
  }

  gl.Uniform1iv(render_state.tex_slots_loc, MAX_TEXTURES, &samplers[0])
  gl.UseProgram(0)

  white_texture := [4]u8 {0xff, 0xff, 0xff, 0xff}
  upload_texture({
    &white_texture[0],
    1,1,
    4,
  })

  init_font_system()
}

push_line_circle :: proc(
    center      : vec2,
    radius      : f32,
    segments    : u32 = 32,
    color       : vec4 = vec4{1, 1, 1, 1},
    angle_begin : f32 = 0,
    arc_angle : f32 = math.TAU, // TAU = 2π (full circle)
) {
    state := &render_state

    seg_count := u32(math.ceil(f32(segments) * (arc_angle / math.TAU)))
    if seg_count < 2 {
        seg_count = 2
    }

    if state.vertex_count + seg_count > MAX_VERTEX_COUNT ||
       state.index_count + seg_count * 2 > MAX_VERTEX_COUNT {
        _flush_frame()
    }

    vc := state.vertex_count
    ic := state.index_count

    step := arc_angle / f32(seg_count - (arc_angle < math.TAU ? 1 : 0))

    for i in 0 ..< seg_count {
        theta := step * f32(i) + angle_begin
        p := vec2{
            center.x + math.cos(theta) * radius,
            center.y + math.sin(theta) * radius,
        }
        state.vertices[vc + i] = RenderVertex{p, color, vec2{0, 0}, 0}
    }

    for i in 0 ..< seg_count - 1 {
        i0 := vc + i
        i1 := vc + (i + 1)
        state.indices[ic + i * 2 + 0] = i0
        state.indices[ic + i * 2 + 1] = i1
    }

    if arc_angle >= math.TAU - 0.0001 {
        last := vc + seg_count - 1
        first := vc
        state.indices[ic + (seg_count - 1) * 2 + 0] = last
        state.indices[ic + (seg_count - 1) * 2 + 1] = first
        state.index_count += seg_count * 2
    } else {
        state.index_count += (seg_count - 1) * 2
    }

    state.vertex_count += seg_count
}

push_line :: proc(begin, end : vec2, color : vec4 = 1.0) {
  state := &render_state

	if state.vertex_count + 2 > MAX_VERTEX_COUNT || state.index_count + 2 > MAX_VERTEX_COUNT {
    _flush_frame()
	}

	vc := state.vertex_count
	ic := state.index_count

	state.vertices[vc + 0] = RenderVertex{begin, color, 0, 0}
	state.vertices[vc + 1] = RenderVertex{end, color, 0, 0}

	state.indices[ic + 0] = vc + 0
	state.indices[ic + 1] = vc + 1

	state.vertex_count += 2
	state.index_count += 2
}

push_line_box :: proc(
	pos, size: vec2,
	color: vec4 = vec4{1, 1, 1, 1},
  pivot : Pivot = .TopLeft
) {
	state := &render_state

	if state.vertex_count + 4 > MAX_VERTEX_COUNT || state.index_count + 8 > MAX_VERTEX_COUNT {
    _flush_frame()
	}

	vc := state.vertex_count
	ic := state.index_count

  offset := -utils.pivot_offset(pivot) * size

	p0 := pos + offset
	p1 := pos + vec2{size.x, 0} + offset
	p2 := pos + vec2{size.x, size.y} + offset
	p3 := pos + vec2{0, size.y} + offset

	state.vertices[vc + 0] = RenderVertex{p0, color, 0, 0}
	state.vertices[vc + 1] = RenderVertex{p1, color, 0, 0}
	state.vertices[vc + 2] = RenderVertex{p2, color, 0, 0}
	state.vertices[vc + 3] = RenderVertex{p3, color, 0, 0}

	state.indices[ic + 0] = vc + 0
	state.indices[ic + 1] = vc + 1
	state.indices[ic + 2] = vc + 1
	state.indices[ic + 3] = vc + 2
	state.indices[ic + 4] = vc + 2
	state.indices[ic + 5] = vc + 3
	state.indices[ic + 6] = vc + 3
	state.indices[ic + 7] = vc + 0


	state.vertex_count += 4
	state.index_count += 8
}

push_rect :: proc(
	pos, size: vec2,
	color: vec4 = vec4{1, 1, 1, 1},
	texcoords: vec4 = vec4{0, 0, 1, 1},
	tex_id: u32 = 0,
  pivot : Pivot = .TopLeft
) {
	state := &render_state

	if state.vertex_count + 4 > MAX_VERTEX_COUNT || state.index_count + 6 > MAX_VERTEX_COUNT {
    _flush_frame()
	}

	vc := state.vertex_count
	ic := state.index_count
  
  offset := -utils.pivot_offset(pivot) * size

	p0 := pos + offset
	p1 := pos + vec2{size.x, 0} + offset
	p2 := pos + vec2{size.x, size.y} + offset
	p3 := pos + vec2{0, size.y} + offset

	uv0 := texcoords.xy
	uv1 := vec2{texcoords.z, texcoords.y}
	uv2 := texcoords.zw
	uv3 := vec2{texcoords.x, texcoords.w}

	state.vertices[vc + 0] = RenderVertex{p0, color, uv0, f32(tex_id)}
	state.vertices[vc + 1] = RenderVertex{p1, color, uv1, f32(tex_id)}
	state.vertices[vc + 2] = RenderVertex{p2, color, uv2, f32(tex_id)}
	state.vertices[vc + 3] = RenderVertex{p3, color, uv3, f32(tex_id)}

	state.indices[ic + 0] = vc + 0
	state.indices[ic + 1] = vc + 1
	state.indices[ic + 2] = vc + 2
	state.indices[ic + 3] = vc + 2
	state.indices[ic + 4] = vc + 3
	state.indices[ic + 5] = vc + 0

	state.vertex_count += 4
	state.index_count += 6
}

clear_target_rgb :: proc(r, g, b : f32) {
  gl.ClearColor(r, g, b, 1.0)
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

clear_target_rgba :: proc(col : vec4) {
  gl.ClearColor(col.r, col.g, col.b, col.a)
  gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

clear_target :: proc {
  clear_target_rgb,
  clear_target_rgba, 
}

begin_frame :: proc(pass : RenderPass) {
  render_state.vertex_count = 0
  render_state.index_count = 0
  render_state.active_pass = pass

  gl.UseProgram(render_state.shader)
  gl.BindVertexArray(render_state.vao)

  coord_space := &render_state.active_pass.coord_space
  gl.UniformMatrix4fv(render_state.view_loc, 1, false, &coord_space.view[0][0])
  gl.UniformMatrix4fv(render_state.proj_loc, 1, false, &coord_space.proj[0][0])
}

_flush_frame :: proc() {
  _draw_frame()
  render_state.vertex_count = 0
  render_state.index_count = 0
}

_draw_frame :: proc() {
  rndr_pass := render_state.active_pass
  gl.BindBuffer(gl.ARRAY_BUFFER, render_state.vbo)
  gl.BufferSubData(gl.ARRAY_BUFFER, 0, cast(int) render_state.vertex_count * size_of(RenderVertex), &render_state.vertices[0])

  gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, render_state.ibo)
  gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, cast(int) render_state.index_count * size_of(u32), &render_state.indices[0])

  mode := to_opengl(rndr_pass.draw_type)
  gl.DrawElements(mode, cast(i32) render_state.index_count, gl.UNSIGNED_INT, nil)
}

end_frame :: proc() {
  _draw_frame()
}

_resize_target :: proc(width, height : i32) {
  gl.Viewport(0, 0, width, height)
}

//======== Opengl Utils================//
@(private) drawtype_to_opengl :: proc(type : DrawType) -> u32 {
  switch type {
  case .Triangle : return gl.TRIANGLES
  case .Line : return gl.LINES
  case : return 0
  }
}

@(private) to_opengl :: proc {
  drawtype_to_opengl,
}

