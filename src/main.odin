package main

import "core:fmt"
import "core:time"
import "core:math"
 
import "engine:app"
import "engine:draw"
import "engine:physics"
import "engine:ui"

main :: proc() {
  app.run(
    width = 1000,
    height = 625,
    title = "game",
    init_proc = init,
    frame_proc = update,
    flags =  .Decorated | .Resizable
  )
}

init :: proc() {

  Temp :: enum {
    A = 0,
    B,
    C,
    D,
  }


  game_init()
}

update :: proc(delta_time: f32) {
  window := app.get_resolution()
  aspect_ratio := window.x / window.y
  camera_space := draw.get_world_space(ctx.camera_position, {aspect_ratio, 1} * ctx.camera_height)
  cursor_pos := app.cursor_pos()
  cursor_w := app.pixels_to_world(cursor_pos, camera_space)

  draw.clear_target(draw.color(0x131313))

  game_update(delta_time * ctx.time_scale)

  player := get_entity(ctx.player_handle)

  if draw.push_frame({
    draw_type = .Triangle,
    coord_space = camera_space
  }) {
    for &entity in get_entities() {
      if entity.slot_free { continue }
      draw.push_rect(
        entity.position,
        entity.size,
        pivot=.MidCenter,
        color=entity.color,
        rotation=entity.rotation
      )
    }

  }


  free_all(context.temp_allocator)
}

