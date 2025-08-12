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
    flags =  .Resizable | .Decorated,
  )
}


init :: proc() {
}

update :: proc(delta_time: f32) {
  window := app.get_resolution()
  camera_space := draw.get_world_space({0,0}, window)

  draw.begin_frame({
    draw_type = .Triangle,
    coord_space = camera_space,
  })
  draw.clear_target(draw.color(0x000000))
  draw.push_rect({0,0}, {255,224}, pivot = .MidCenter)
  draw.end_frame()
}
