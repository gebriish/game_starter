package main

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
  render.update_ui_proj(&camera)

  render.upload_projection(&camera)
  render.upload_view(&camera)
}


core_app_frame :: proc() 
{
  render.update_view(&camera)
  render.upload_view(&camera)

  render.clear_frame(COLOR_PALETTE[0])
  render.begin_frame()

  if app.is_key_pressed(app.KEY_M) {
    render.wireframe_mode(true)
  }
  else if app.is_key_pressed(app.KEY_N) {
    render.wireframe_mode(false)
  }

  @(static) select_begin : [2]f32

  if app.is_mouse_pressed(app.MOUSE_BUTTON_RIGHT) {
    select_begin = app.get_cursor_pos()
  }

  if app.is_mouse_down(app.MOUSE_BUTTON_RIGHT) {
    cursor_pos := app.get_cursor_pos()

    begin_pos := [2]f32 {math.min(select_begin.x, cursor_pos.x), math.min(select_begin.y, cursor_pos.y)}
    end_pos := [2]f32 {math.max(select_begin.x, cursor_pos.x), math.max(select_begin.y, cursor_pos.y)}
    
    {
      render.push_rect(
        begin_pos,
        end_pos - begin_pos,
        render.hex_code_to_4f({hexcode = 0xebdbc7ff}),
        0.0,
        4.0,
      )

    }
  }

  render.end_frame()
}

core_app_resize :: proc(width, height : i32)
{
  render.set_viewport(width, height)
  camera.size = {cast(f32) width, cast(f32) height}
  render.update_ui_proj(&camera)
  render.upload_projection(&camera)
}

core_app_shutdown :: proc() 
{
}

