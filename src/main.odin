package user

import "base:runtime"

import "core:math/linalg"
import "core:fmt"
import "core:time"
import "core:math"
import "core:strings"

import "engine:app"
import "engine:render"
import "engine:utils"

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
    shutdown_proc = core_app_shutdown,
  )
}

core_app_init :: proc()
{
}

core_app_frame :: proc() 
{
  delta_time := app.get_delta_time()
  window :=app.get_resolution()
  mouse_pos := app.get_mouse_pos()

  render.clear_frame({hexcode = 0x131313_ff})
  render.wireframe_mode(app.is_key_pressed(.W))
 
  if render.begin_pass(get_screen_space()) {
    top_corner := utils.pivot_in_rect(0, window, .TopRight)

    render.push_rect_rounded(10, mouse_pos - 20, radii = {10, 32, 0, 12})
    render.draw_text(fmt.tprintf("frame time: %.3f ms\nfps: %v", 1e3 * delta_time, int(1.0/delta_time)), top_corner, pivot = .TopRight)
  }


  free_all(context.temp_allocator)
}

core_app_shutdown :: proc() {
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
