package main

import "core:fmt"
import "core:time"
import "core:math"
 
import "engine:app"
import "engine:draw"

main :: proc() {
  app.run(
    width = 1000,
    height = 625,
    title = "game",
    init_proc = init,
    frame_proc = update,
    flags =  .Resizable | .Decorated
  )
}

init :: proc() {
}

accum : u32 = 32

update :: proc(delta_time: f32) {
  window := app.get_resolution()
  camera_space := draw.get_screen_space(window)
  cursor_w := app.pixels_to_world(app.cursor_pos(), camera_space)

  draw.clear_target(draw.color(0x000000))
  draw.begin_frame({
    draw_type = .Triangle,
    coord_space = camera_space,
  })
  draw.text(fmt.tprintf("[%.0f, %.0f]", cursor_w.x, cursor_w.y), cursor_w, pivot = .BottomCenter)
  draw.end_frame()

  free_all(context.temp_allocator)
}
