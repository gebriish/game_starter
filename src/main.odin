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
  game_init()
}


update :: proc(delta_time: f32) {
  window := app.get_resolution()
  aspect_ratio := window.x / window.y
  camera_space : draw.CoordSpace
  if aspect_ratio > 1.0 {
    camera_space = draw.get_world_space(ctx.camera_position, {1.0,1.0/aspect_ratio} * ctx.camera_height)
  } else {
    camera_space = draw.get_world_space(ctx.camera_position, {aspect_ratio, 1.0} * ctx.camera_height)
  }
  cursor_w := app.pixels_to_world(app.cursor_pos(), camera_space)

  game_update(delta_time)

  draw.clear_target(draw.color(0x131313))

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
      )
    }

    for &entity in get_entities() {
      if entity.slot_free { continue }
      draw.text(fmt.tprintf("%p", &entity),entity.position,pivot=.TopCenter,color=draw.color(0xb8bb26))
    }
  }

  screen_space := draw.get_screen_space(window)

  if draw.push_frame({
    draw_type = .Triangle,
    coord_space = screen_space
  }) {
    debug_string := fmt.tprintf(
      "gamepad_0 connected (%v)", 
      app.is_gamepad_connected(0)
    )
    draw.text(debug_string, 10)
  }

  free_all(context.temp_allocator)
}

