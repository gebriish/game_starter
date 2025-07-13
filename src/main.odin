package main

import "core:fmt"
import "core:time"
import "core:math"

import "engine:app"
import "engine:render"
import "engine:ui"

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

camera := render.Camera {
  position = 0,
  size = 1.0
}

core_app_init :: proc()
{
  render.init()

  camera.size = app.get_resolution()
  render.update_view(&camera)
  render.update_proj(&camera)

  render.upload_projection(&camera)
  render.upload_view(&camera)
}

core_app_frame :: proc() 
{
  delta_time := app.get_delta_time()
  window_resolution :=app.get_resolution()
  cursor_pos := app.get_cursor_pos()

  render.wireframe_mode(app.is_key_pressed(app.KEY_W))

  ui.begin_frame(window_resolution)
 
  ui.end_frame()

  
  render.begin_frame();
  render.end_frame();
}

core_app_resize :: proc(width, height : i32)
{
  camera.size = {cast(f32) width, cast(f32) height}
  render.update_ui_proj(&camera)
  render.upload_projection(&camera)
  render.set_viewport(width, height)
}

core_app_shutdown :: proc() 
{
}

