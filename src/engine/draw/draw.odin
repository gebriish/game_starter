package draw

import "core:math/linalg"
import "core:math"
import "core:fmt"

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

ndc_to_world_custom :: proc(coord : CoordSpace, ndc : [2]f32) -> [2]f32 {
  ndc_pos := [4]f32{ndc.x, ndc.y, 0.0, 1.0};
  world_pos4 := coord.inverse * ndc_pos; 
  return world_pos4.xy; // dont care about .w scaling
}

ndc_to_world_default :: proc(ndc : [2]f32) -> [2]f32 {
  coord := &render_state.active_pass.coord_space
  ndc_pos := [4]f32{ndc.x, ndc.y, 0.0, 1.0};
  world_pos4 := coord.inverse * ndc_pos; 
  return world_pos4.xy;
}

ndc_to_world  :: proc {
  ndc_to_world_default,
  ndc_to_world_custom,
}

get_world_space :: proc(
  cam_pos, cam_size : vec2,
  near : f32 = -1.0,
  far : f32 = 1024.0,
  rotation : f32 = 0.0,
) -> CoordSpace {
  half_size := cam_size * 0.5
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
  rotation : f32 = 0.0,
) -> CoordSpace {
  proj := linalg.matrix_ortho3d(
    0, size.x, 
    size.y, 0, 
    near, far, false
  )
  up := vec2{-math.sin(rotation), math.cos(rotation)}
  view := linalg.matrix4_look_at(
    [3]f32 {0, 0, 0},
    [3]f32 {0, 0,-1},
    [3]f32 {0,-1, 0},
  )
  inverse := linalg.inverse(proj * view)
  return {proj, view, inverse}
}
