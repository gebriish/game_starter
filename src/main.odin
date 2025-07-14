package main

import "core:math/linalg"
import "core:fmt"
import "core:time"
import "core:math"

import "engine:app"
import "engine:render"

/*
COLOR PALETTE 
background0 : #1f1f1f
background1 : #353535
foreground0 : #d1d1d1
foreground1 : #d1cfc0
highlights0 : #f76753
*/

COLOR_PALETTE := [5]render.HexColor {
  {hexcode = 0x1f1f1f_ff},
  {hexcode = 0x353535_ff},
  {hexcode = 0xd1d1d1_ff},
  {hexcode = 0xd1cfc0_ff},
  {hexcode = 0xf76753_ff},
}

get_world_space :: proc () -> render.CoordSpace
{
  res := app.get_resolution()

  coord := render.CoordSpace {
    projection = linalg.matrix_ortho3d(
      0, res.x, res.y, 0, MAX_Z_LAYERS, -1, false
    ),
    camera = linalg.matrix4_look_at(
      [3]f32 {0, 0, 0},
      [3]f32 {0, 0, -1},
      [3]f32 {0, 1, 0},
    )
  }

  return coord
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
    resize_proc = core_app_resize
  )
}

core_app_init :: proc()
{
  render.init()
  render.set_coord_space(get_world_space())
}

core_app_frame :: proc() 
{
  delta_time := app.get_delta_time()
  window_resolution :=app.get_resolution()
  cursor_pos := app.get_cursor_pos()

  render.wireframe_mode(app.is_key_pressed(app.KEY_W))

  render.clear_frame({hexcode = 0x000000_ff})

  render.begin_frame();
  render.push_rect(0, window_resolution, render.linear(0x282828_ff))
  render.end_frame();
}

core_app_resize :: proc(width, height : i32) 
{
  render.set_viewport(width, height)
  render.set_coord_space(get_world_space())
}

core_app_shutdown :: proc() 
{
}

