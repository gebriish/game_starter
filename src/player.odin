package main

import "engine:app"

control_player :: proc(entity : ^Entity, delta_time: f32) {
  x_move : f32

  if app.is_key_pressed(.RIGHT) && !app.is_key_pressed(.LEFT) {
    x_move = 1.0
  }
  else if app.is_key_pressed(.LEFT) && !app.is_key_pressed(.RIGHT) {
    x_move = -1.0
  }

  if app.on_key_down(.SPACE) {
    entity.velocity.y = -300
  }

  if entity.position.y > 0.001 {
    entity.position.y = 0.0
    entity.velocity.y = 0.0
  } else {
    entity.velocity.y += 980 * delta_time
  }

  ctx.camera_position += (entity.position - ctx.camera_position - {0,100}) * 10 * delta_time
  entity.velocity.x = 300 * x_move
}
