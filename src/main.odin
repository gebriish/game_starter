package main

import "core:fmt"
import "core:time"
 
import "engine:app"
import "engine:draw"

main :: proc() {
  app.run(
    width = 1000,
    height = 625,
    title = "game",
    init_proc = init,
    frame_proc = update,
    flags =  .Maximized | .Resizable
  )
}

init :: proc() {
  game_init()
}


update :: proc(delta_time: f32) {
  window := app.get_resolution()
  aspect_ratio := window.x / window.y
  camera_space := draw.get_world_space(ctx.camera_position, {aspect_ratio, 1} * ctx.camera_height)
  cursor_w := app.pixels_to_world(app.cursor_pos(), camera_space)

  draw.clear_target(draw.color(0x131313))

  game_update(delta_time)

  if draw.push_frame({
    draw_type = .Triangle,
    coord_space = camera_space
  }) {
    for &entity in get_entities() {
      if entity.slot_free { continue }
      draw.push_rect(
        entity.position,
        entity.size,
        pivot=entity.pivot,
        color=entity.color,
        rotation=entity.rotation
      )
    }
  }

  screen_space := draw.get_screen_space(window)

  if draw.push_frame({
    draw_type = .Triangle,
    coord_space = screen_space
  }) {
    debug_string := fmt.tprintf(
      `gamepad_0 connected (%v)
fps: %v`, 
      app.is_gamepad_connected(0),
      int(1.0/delta_time)
    )
    draw.text(debug_string, 10)
  }

  free_all(context.temp_allocator)
}

