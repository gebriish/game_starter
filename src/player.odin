package main

import "engine:app"

control_player :: proc(entity : ^Entity, delta_time: f32) {
  x_move : f32

  if !app.is_gamepad_connected(0) {
    if app.is_key_pressed(.Right) && !app.is_key_pressed(.Left) {
      x_move = 1.0
    }
    else if app.is_key_pressed(.Left) && !app.is_key_pressed(.Right) {
      x_move = -1.0
    }

    if app.on_key_down(.Space) {
      entity.velocity.y = -300
    }
  } else {
    x_move = app.get_gamepad_axis(0, .Left_X)

    if app.on_gamepad_button_down(0, .A) {
      entity.velocity.y = -300
    }

  }


  if entity.position.y > 0.001 {
    entity.position.y = 0.0
    entity.velocity.y = 0.0
  } else {
    entity.velocity.y += 980 * delta_time
  }

  ctx.camera_position += (entity.position - ctx.camera_position) * 10 * delta_time
  entity.velocity.x = 300 * x_move
}
