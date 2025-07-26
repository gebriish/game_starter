package user

import "core:math/linalg"
import "core:fmt"
import "core:time"
import "core:math"
import "core:strings"

import "engine:app"
import "engine:render"
import "engine:utils"
import "engine:ui"

COLOR_PALETTE := [5]render.HexColor {
  {hexcode = 0x1f1f1f_ff},
  {hexcode = 0x353535_ff},
  {hexcode = 0xd1d1d1_ff},
  {hexcode = 0xd1cfc0_ff},
  {hexcode = 0xf76753_ff},
}

main :: proc()
{
  app.run(
    window_x = 640,
    window_y = 480,
    title = "App",
    hint_flags = app.WINDOW_HINT_DECORATED | app.WINDOW_HINT_RESIZABLE,
    init_proc = core_app_init,
    frame_proc = core_app_frame,
  )
}


core_app_init :: proc()
{
}

core_app_frame :: proc() 
{
  delta_time := app.get_delta_time()
  window := app.get_resolution()
  mouse_pos := app.get_mouse_pos()

  render.clear_frame({hexcode = 0x000000ff})
  render.wireframe_mode(app.is_key_pressed(.W))
  prev_pos : [2]f32
 


  if render.push_pass(get_screen_space()) {
  }


  free_all(context.temp_allocator)
}

get_world_space :: proc () -> render.CoordSpace
{
  res := app.get_resolution() * 0.5

  coord := render.CoordSpace {
    projection = linalg.matrix_ortho3d(
      -res.x, res.x, res.y, -res.y, -1, MAX_Z_LAYERS, false
    ),
    camera = linalg.matrix4_look_at(
      [3]f32 {0, 0, 0},
      [3]f32 {0, 0,-1},
      [3]f32 {0, 1, 0},
    )
  }
  coord.inverse = linalg.inverse(coord.projection * coord.camera)
  return coord
}

get_screen_space :: proc () -> render.CoordSpace
{
  res := app.get_resolution()

  coord := render.CoordSpace {
    projection = linalg.matrix_ortho3d(
      0, res.x, res.y, 0, -1, MAX_Z_LAYERS, false
    ),
    camera = linalg.matrix4_look_at(
      [3]f32 {0, 0, 0},
      [3]f32 {0, 0,-1},
      [3]f32 {0, 1, 0},
    )
  }
  coord.inverse = linalg.inverse(coord.projection * coord.camera)
  return coord
}

ear_clip :: proc(points: [][2]f32) -> [dynamic]u32 {
  triangles := make([dynamic]u32, context.temp_allocator)

  n := len(points)
  if n < 3 do return triangles

  indices := make([dynamic]u32, context.temp_allocator)
  for i in 0..<n {
    append(&indices, u32(i))
  }

  // Triangulate
  for len(indices) > 3 {
    ear_found := false

    for i in 0..<len(indices) {
      if is_ear(points[:], indices[:], i) {
        // Add triangle
        prev := (i - 1 + len(indices)) % len(indices)
        curr := i
        next := (i + 1) % len(indices)

        append(&triangles, indices[next])
        append(&triangles, indices[curr]) 
        append(&triangles, indices[prev])

        // Remove the ear vertex
        ordered_remove(&indices, i)
        ear_found = true
        break
      }
    }

    // Fallback if no ear found (degenerate polygon)
    if !ear_found {
      break
    }
  }

  // Add final triangle
  if len(indices) == 3 {
    append(&triangles, indices[2])
    append(&triangles, indices[1])
    append(&triangles, indices[0])
  }

  return triangles
}

is_ear :: proc(points: [][2]f32, indices: []u32, i: int) -> bool {
  n := len(indices)
  if n < 3 do return false

  prev := (i - 1 + n) % n
  curr := i
  next := (i + 1) % n

  a := points[indices[prev]]
  b := points[indices[curr]]
  c := points[indices[next]]

  // Check if triangle is oriented counter-clockwise (convex)
  if !is_convex(a, b, c) do return false

  // Check if any other vertex is inside this triangle
  for j in 0..<n {
    if j == prev || j == curr || j == next do continue

    p := points[indices[j]]
    if point_in_triangle(p, a, b, c) {
      return false
    }
  }

  return true
}

is_convex :: proc(a, b, c: [2]f32) -> bool {
  return cross_product_2d(b - a, c - b) > 0
}

cross_product_2d :: proc(v1, v2: [2]f32) -> f32 {
  return v1.x * v2.y - v1.y * v2.x
}

point_in_triangle :: proc(p, a, b, c: [2]f32) -> bool {
  v0 := c - a
  v1 := b - a  
  v2 := p - a

  dot00 := dot(v0, v0)
  dot01 := dot(v0, v1)
  dot02 := dot(v0, v2)
  dot11 := dot(v1, v1)
  dot12 := dot(v1, v2)

  inv_denom := 1.0 / (dot00 * dot11 - dot01 * dot01)
  u := (dot11 * dot02 - dot01 * dot12) * inv_denom
  v := (dot00 * dot12 - dot01 * dot02) * inv_denom

  return (u >= 0) && (v >= 0) && (u + v <= 1)
}

dot :: proc(a, b: [2]f32) -> f32 {
  return a.x * b.x + a.y * b.y
}
