package draw

import "core:math/linalg"
import "core:math"
import "core:fmt"

import "engine:utils"

color_hex :: proc(col: u32) -> vec4 {
  r := f32((col >> 16) & 0xFF) / 255.0
  g := f32((col >> 8) & 0xFF) / 255.0
  b := f32(col & 0xFF) / 255.0
  a := f32(1.0)
  return vec4{r, g, b, a}
}

color_rgba :: proc(r, g, b : f32, a : f32 = 1) -> vec4 {
  return {r,g,b,a} 
}

color :: proc {
  color_hex,
  color_rgba,
}

ndc_to_world :: proc(coord : CoordSpace, ndc : [2]f32) -> [2]f32 {
  ndc_pos := [4]f32{ndc.x, ndc.y, 0.0, 1.0};
  world_pos4 := coord.inverse * ndc_pos; 
  return world_pos4.xy; // dont care about .w scaling
}

get_world_space :: proc(
  cam_pos, cam_size : vec2,
  near : f32 = -1.0,
  far : f32 = 1024.0,
  rotation : f32 = 0.0,
) -> CoordSpace {
  half_size := cam_size
  proj := linalg.matrix_ortho3d(
    -half_size.x, half_size.x, 
    half_size.y, -half_size.y, 
    near, far, false
  )
  up := vec2{-math.sin(rotation), math.cos(rotation)}
  view := linalg.matrix4_look_at(
    [3]f32 {cam_pos.x, cam_pos.y, 0},
    [3]f32 {cam_pos.x, cam_pos.y,-1},
    [3]f32 {up.x,  up.y,  0},
  )
  inverse := linalg.inverse(proj * view)
  return {proj, view, inverse}
}

get_screen_space :: proc(
  size : vec2,
  near : f32 = -1.0,
  far : f32 = 1024.0,
) -> CoordSpace {
  proj := linalg.matrix_ortho3d(
    0, size.x, 
    size.y, 0, 
    near, far, false
  )
  view := linalg.matrix4_look_at(
    [3]f32 {0,0, 0},
    [3]f32 {0,0,-1},
    [3]f32 {0,1, 0},
  )
  inverse := linalg.inverse(proj * view)
  return {proj, view, inverse}
}

text :: proc(
  value : string,
  pos : vec2,
  color : vec4 = 1,
  scale : f32 = 1,
  pivot : Pivot = .TopLeft
) -> vec4 {
  using render_state
  if len(value) == 0 do return {}

  // Load glyphs to atlas
  for codepoint in value {
    add_glyph_to_atlas(codepoint)
  }
  update_font_atlas()

  max_width: f32 = 0
  total_height: f32 = 0
  line_width: f32 = 0
  line_height := (font_atlas.font.ascent - font_atlas.font.descent + font_atlas.font.line_gap) * scale

  for codepoint in value {
    if codepoint == '\n' {
      max_width = math.max(max_width, line_width)
      line_width = 0
      total_height += line_height
      continue
    }
    glyph, found := font_atlas.glyphs[codepoint]
    if !found do continue
    line_width += glyph.xadvance * scale
  }
  max_width = math.max(max_width, line_width)
  total_height += line_height

  text_box_size := vec2{max_width, total_height}
  box_offset := -utils.pivot_offset(pivot) * text_box_size

  start_x := pos.x + box_offset.x
  start_y := pos.y + box_offset.y

  x := start_x
  y := start_y
  for codepoint in value {
    if codepoint == '\n' {
      x = start_x
      y += line_height
      continue
    }
    glyph, found := font_atlas.glyphs[codepoint]
    if !found do continue

    if glyph.x1 > glyph.x0 && glyph.y1 > glyph.y0 {
      char_size := vec2{
        f32(glyph.x1 - glyph.x0) * scale,
        f32(glyph.y1 - glyph.y0) * scale,
      }
      char_pos := vec2{
          x + glyph.xoff * scale,
          y + (glyph.yoff + f32(font_atlas.row_height))  * scale
      }
      uv := vec4{
        f32(glyph.x0) / f32(font_atlas.atlas_width),
        f32(glyph.y0) / f32(font_atlas.atlas_height),
        f32(glyph.x1) / f32(font_atlas.atlas_width),
        f32(glyph.y1) / f32(font_atlas.atlas_height),
      }
      push_rect(char_pos, char_size, color, uv, font_atlas.texture_id)
    }
    x += glyph.xadvance * scale
  }

  return {start_x, start_y, max_width, total_height}
}

