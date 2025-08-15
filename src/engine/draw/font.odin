package draw

import "core:fmt"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"
import stbtt "vendor:stb/truetype"

Font :: struct {
  font_data : []u8,
  font_info : stbtt.fontinfo,
  scale : f32,
  ascent : f32,
  descent : f32,
  line_gap : f32,
}

AtlasGlyph :: struct {
  codepoint : rune,
  x0, y0, x1, y1 : i32,
  xoff, yoff : f32,
  xadvance : f32,
}

DynamicFontAtlas :: struct {
  font : Font,
  texture_id : u32,
  atlas_width: i32,
  atlas_height : i32,
  atlas_data : []u8,
  glyphs : map[rune]AtlasGlyph,
  current_x, current_y : i32,
  row_height:i32,
  dirty : b32,
}


init_dynamic_font_atlas :: proc(font_path : string, initial_size : i32 = 512, font_height: f32 = 15) -> bool {
  using stbtt
  using render_state
  
  font_data, read_ok := os.read_entire_file(font_path)
  if !read_ok {
    fmt.eprintln("Failed to load font:", font_path)
    return false
  }

  if !InitFont(&font_atlas.font.font_info, raw_data(font_data), 0) {
    fmt.eprintln("Failed to initialize font")
    delete(font_data)
    return false
  }

  font_atlas.font.font_data = font_data
  font_atlas.font.scale = ScaleForPixelHeight(&font_atlas.font.font_info, font_height)

  ascent, descent, line_gap: i32
  GetFontVMetrics(&font_atlas.font.font_info, &ascent, &descent, &line_gap)
  font_atlas.font.ascent = f32(ascent) * font_atlas.font.scale
  font_atlas.font.descent = f32(descent) * font_atlas.font.scale
  font_atlas.font.line_gap = f32(line_gap) * font_atlas.font.scale

  font_atlas.atlas_width = initial_size
  font_atlas.atlas_height = initial_size
  font_atlas.atlas_data = make([]u8, initial_size * initial_size)
  font_atlas.glyphs = make(map[rune]AtlasGlyph)

  font_atlas.current_x = 1
  font_atlas.current_y = 1
  font_atlas.row_height = 0

  texture := Texture{
    data = raw_data(font_atlas.atlas_data),
    width = font_atlas.atlas_width,
    height = font_atlas.atlas_height,
    channels = 1,
  }

  font_atlas.texture_id = upload_texture(texture, .Font)
  font_atlas.dirty = false

  return true
}

add_glyph_to_atlas :: proc(codepoint: rune) -> bool {
  using stbtt
  using render_state
  
  if codepoint in font_atlas.glyphs {
    return true
  }
  
  glyph_index := FindGlyphIndex(&font_atlas.font.font_info, codepoint)
  if glyph_index == 0 && codepoint != ' ' {
    return false
  }
  
  SDF_PADDING :: 8  // Padding around the glyph for SDF
  SDF_ONEDGE_VALUE :: 128  // Value representing the edge (0-255)
  SDF_PIXEL_DIST_SCALE :: 64.0  // How many SDF units per pixel
  
  // Get the actual SDF dimensions first
  bitmap_width, bitmap_height: i32
  glyph_sdf := GetGlyphSDF(&font_atlas.font.font_info, 
    font_atlas.font.scale,
    glyph_index, 
    SDF_PADDING,  // padding
    SDF_ONEDGE_VALUE,  // onedge_value (0-255)
    SDF_PIXEL_DIST_SCALE,  // pixel_dist_scale
    &bitmap_width, 
    &bitmap_height, 
    nil,  // xoff (can be nil)
    nil)  // yoff (can be nil)
  
  defer if glyph_sdf != nil { FreeSDF(glyph_sdf, nil) }
  
  glyph_width := bitmap_width
  glyph_height := bitmap_height
  
  if glyph_width <= 0 || glyph_height <= 0 {
    advance_width: i32
    GetGlyphHMetrics(&font_atlas.font.font_info, glyph_index, &advance_width, nil)
    font_atlas.glyphs[codepoint] = AtlasGlyph{
      codepoint = codepoint,
      x0 = 0, y0 = 0, x1 = 0, y1 = 0,
      xoff = 0, yoff = 0,
      xadvance = f32(advance_width) * font_atlas.font.scale,
    }
    return true
  }
  
  if font_atlas.current_x + glyph_width + 1 > font_atlas.atlas_width {
    font_atlas.current_x = 1
    font_atlas.current_y += font_atlas.row_height + 1
    font_atlas.row_height = 0
  }
  
  if font_atlas.current_y + glyph_height + 1 > font_atlas.atlas_height {
    if !expand_atlas() {
      fmt.eprintln("Failed to expand font atlas")
      return false
    }
  }
  
  glyph_x := font_atlas.current_x
  glyph_y := font_atlas.current_y
  
  // Copy SDF data to atlas
  if glyph_sdf != nil && glyph_width > 0 && glyph_height > 0 {
    for row in 0..<glyph_height {
      atlas_y := glyph_y + row
      if atlas_y >= font_atlas.atlas_height { break }
      
      for col in 0..<glyph_width {
        atlas_x := glyph_x + col
        if atlas_x >= font_atlas.atlas_width { break }
        
        atlas_idx := atlas_y * font_atlas.atlas_width + atlas_x
        sdf_idx := row * glyph_width + col
        
        if int(atlas_idx) < len(font_atlas.atlas_data) && sdf_idx >= 0 {
          font_atlas.atlas_data[atlas_idx] = (cast([^]u8)glyph_sdf)[sdf_idx]
        }
      }
    }
  }
  
  advance_width: i32
  GetGlyphHMetrics(&font_atlas.font.font_info, glyph_index, &advance_width, nil)
  
  // Get bitmap box for offset calculations
  x0, y0, x1, y1: i32
  GetGlyphBitmapBox(&font_atlas.font.font_info, glyph_index, font_atlas.font.scale, font_atlas.font.scale, &x0, &y0, &x1, &y1)
  
  // Store glyph info with correct offsets
  font_atlas.glyphs[codepoint] = AtlasGlyph{
    codepoint = codepoint,
    x0 = glyph_x,
    y0 = glyph_y,
    x1 = glyph_x + glyph_width,
    y1 = glyph_y + glyph_height,
    xoff = f32(x0) - SDF_PADDING,  // Adjust for padding
    yoff = f32(y0) - SDF_PADDING,  // Adjust for padding
    xadvance = f32(advance_width) * font_atlas.font.scale,
  }
  
  font_atlas.current_x += glyph_width + 1
  font_atlas.row_height = max(font_atlas.row_height, glyph_height)
  font_atlas.dirty = true
  
  return true
}

expand_atlas :: proc() -> bool {
  using render_state

  new_width := font_atlas.atlas_width * 2
  new_height := font_atlas.atlas_height * 2

  if new_width > 4096 || new_height > 4096 {
    fmt.eprintln("Font atlas size limit reached")
    return false
  }

  new_data := make([]u8, new_width * new_height)

  for row in 0..<font_atlas.atlas_height {
    old_start := row * font_atlas.atlas_width
    new_start := row * new_width
    copy(new_data[new_start:new_start + font_atlas.atlas_width], 
      font_atlas.atlas_data[old_start:old_start + font_atlas.atlas_width])
  }

  delete(font_atlas.atlas_data)
  font_atlas.atlas_data = new_data
  font_atlas.atlas_width = new_width
  font_atlas.atlas_height = new_height

  free_texture(font_atlas.texture_id)

  texture := Texture{
    data = raw_data(font_atlas.atlas_data),
    width = font_atlas.atlas_width,
    height = font_atlas.atlas_height,
    channels = 1,
  }

  font_atlas.texture_id = upload_texture(texture, .Font)
  font_atlas.dirty = false

  fmt.printf("Font atlas expanded to %dx%d\n", new_width, new_height)
  return true
}

add_glyphs_from_string :: proc(text: string) {
  for codepoint in text {
    add_glyph_to_atlas(codepoint)
  }
}

update_font_atlas :: proc() {
  using render_state
  if !font_atlas.dirty {
    return
  }

  update_texture_unsafe(
    font_atlas.texture_id, 
    font_atlas.atlas_width, 
    font_atlas.atlas_height, 
    raw_data(font_atlas.atlas_data)
  )

  font_atlas.dirty = false
}

preload_ascii :: proc() {
  for ch in 32..<127 {
    add_glyph_to_atlas(rune(ch))
  }
  update_font_atlas()
}

init_font_system :: proc() {
  if !init_dynamic_font_atlas(FONT_PATH, 512, FONT_HEIGHT) {
    fmt.eprintln("Failed to initialize font system")
    return
  }
  //preload_ascii()
}
