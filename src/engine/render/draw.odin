package render

import "core:strings"
import "core:math"
import "core:fmt"

import "engine:utils"

CoordSpace :: struct {
  projection, camera, inverse : matrix[4,4]f32
}

set_coord_space :: #force_inline proc(coord : CoordSpace) 
{
  _render_state.coord_space = coord
  upload_projection(&_render_state.coord_space)
  upload_view(&_render_state.coord_space)
}

@(deferred_none=_end_frame)
begin_pass :: proc(coord : CoordSpace) -> bool
{
  set_coord_space(coord)
  _begin_frame()
  return true
}

set_z_layer :: #force_inline proc(z : f32) 
{
  _render_state.z_position = -z
}

@(deferred_out=set_z_layer) push_z_layer :: proc(z : f32 = -1.0) -> f32 
{
  original := _render_state.z_position
  set_z_layer(z > 0 ? z : original + 1)
  return original
}

screen_to_world :: proc(coord: [2]f32, screen : [2]f32) -> [2]f32 
{
  ndc_x := (2.0 * coord.x / screen.x) - 1.0;
  ndc_y := 1.0 - (2.0 * coord.y / screen.y);
  ndc_pos := [4]f32{ndc_x, ndc_y, 0.0, 1.0};
  world_pos4 := _render_state.coord_space.inverse * ndc_pos;
  if world_pos4.w != 0.0 {
    world_pos4 /= world_pos4.w;
  }
  return world_pos4.xy;
}

world_to_screen :: proc(world : [2]f32, screen : [2]f32) -> [2]f32
{
  using _render_state.coord_space
  return (projection * camera * [4]f32 {world.x, world.y, 0.0, 1.0}).xy
}

coord_space :: proc() -> CoordSpace {
  return _render_state.coord_space
}

_FONT_ATLAS_DIM :: [2]u32 {16, 8} // Number of glyphs in (columns, rows)
_FONT_TEXTURE_SIZE :: [2]u32 {96, 96} // Actual texture pixel dimensions

_GLYPH_SIZE :: [2]f32 {
  f32(_FONT_TEXTURE_SIZE.x) / f32(_FONT_ATLAS_DIM.x),
  f32(_FONT_TEXTURE_SIZE.y) / f32(_FONT_ATLAS_DIM.y),
}
_UV_PER_GLYPH :: [2]f32 {
  1.0 / f32(_FONT_ATLAS_DIM.x),
  1.0 / f32(_FONT_ATLAS_DIM.y),
}
_GLYPH_TRIM :: [4]f32 {1,1,0,1}
_PX_PER_UV :: [2]f32{
  1.0 / f32(_FONT_TEXTURE_SIZE.x),
  1.0 / f32(_FONT_TEXTURE_SIZE.y),
}

draw_text :: proc(
  text       : string,
  pos        : [2]f32,
  color      : [4]f32 = {1,1,1,1},
  scale      : f32 = 2.0,
  pivot      : utils.Pivot = .TopLeft,
) -> [4]f32 {
  total_size : [2]f32 = {0,0}
  line_width : f32    = 0

  for char, i in text {
    if char == '\n' {
      total_size.x = math.max(total_size.x, line_width)
      line_width = 0
      total_size.y += _GLYPH_SIZE.y
      continue
    }
    if char == '\t' {
      line_width += _GLYPH_SIZE.x * 4
      continue
    }
    line_width += _GLYPH_SIZE.x
    if i == len(text)-1 {
      total_size.x = math.max(total_size.x, line_width)
      total_size.y += _GLYPH_SIZE.y
    }
  }

  total_size *= scale
  pivot_offset := total_size * utils.pivot_scale(pivot)
  base_pos := pos - pivot_offset

  x: f32 = 0
  y: f32 = 0
  for char in text {
    if char == '\n' {
      x = 0
      y += _GLYPH_SIZE.y
      continue
    }
    if char == '\t' {
      x += _GLYPH_SIZE.x * 4
      continue
    }
    if char == ' ' {
      x += _GLYPH_SIZE.x
      continue
    }

    ascii := u32(char)
    idx : u32
    if ascii < 33 || ascii > 126 {
      idx = 0
    } else {
      idx = ascii - 32
    }

    atlas_xy := [2]f32{
      f32(idx % _FONT_ATLAS_DIM.x),
      f32(idx / _FONT_ATLAS_DIM.x),
    }

    uv0 := atlas_xy * _UV_PER_GLYPH + [2]f32{
      _GLYPH_TRIM[0] * _PX_PER_UV[0],
      _GLYPH_TRIM[1] * _PX_PER_UV[1],
    }
    uv1 := (atlas_xy + [2]f32{1,1}) * _UV_PER_GLYPH - [2]f32{
      _GLYPH_TRIM[2] * _PX_PER_UV[0],
      _GLYPH_TRIM[3] * _PX_PER_UV[1],
    }

    trimmed_size := _GLYPH_SIZE - [2]f32{
      _GLYPH_TRIM[0] + _GLYPH_TRIM[2],
      _GLYPH_TRIM[1] + _GLYPH_TRIM[3],
    }

    glyph_pos := base_pos + ([2]f32{x + _GLYPH_TRIM[0], y + _GLYPH_TRIM[1]}) * scale
    push_rect(glyph_pos, trimmed_size * scale, color, {uv0.x, uv0.y, uv1.x, uv1.y}, tex_id = FONT_TEXTURE)

    x += _GLYPH_SIZE.x
  }

  return {base_pos.x, base_pos.y, total_size.x, total_size.y}
}

draw_text_aligned :: proc (
  text : string,
  pos : [2]f32,
  color : [4]f32 = {1,1,1,1},
  scale : f32 = 2.0,
  max_width : f32 = -1.0,
  alignment : utils.XAlignment = .Left,
  pivot     : utils.Pivot = .TopLeft
) {
  if max_width <= _GLYPH_SIZE.x * scale {
    draw_text(text, pos, color, scale, pivot)
    return
  }

  x_base, y : f32 = pos.x, pos.y
  slice_begin : int = 0
  last_space  : int = -1
  line_width  : f32 = 0

  i := 0
  for i < len(text) {
    char := text[i]

    if char == '\n' || line_width + _GLYPH_SIZE.x * scale > max_width {
      break_index := i
      if char != '\n' && last_space > slice_begin {
        break_index = last_space
      }

      string_slice := text[slice_begin : break_index]

      line_len := len(string_slice)
      actual_width := f32(line_len) * _GLYPH_SIZE.x * scale

      x := x_base
      if alignment == .Center {
        x += (max_width - actual_width) / 2
      } else if alignment == .Right {
        x += (max_width - actual_width)
      }

      draw_text(string_slice, {x, y}, color, scale)

      y += _GLYPH_SIZE.y * scale

      slice_begin = i + 1 if char == '\n' else break_index + 1
      i = slice_begin
      line_width = 0
      last_space = -1
      continue
    }

    if char == ' ' {
      last_space = i
    }

    line_width += _GLYPH_SIZE.x * scale
    i += 1 if char != '\t' else 4
  }

  // Final line
  if slice_begin < len(text) {
    string_slice := text[slice_begin:]
    line_len := len(string_slice)
    actual_width := f32(line_len) * _GLYPH_SIZE.x * scale

    x := x_base
    if alignment == .Center {
      x += (max_width - actual_width) / 2
    } else if alignment == .Right {
      x += (max_width - actual_width)
    }
    draw_text(string_slice, {x, y}, color, scale)
  }
}
