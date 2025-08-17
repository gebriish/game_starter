package main

import "core:fmt"

import "engine:app"
import "engine:draw"

FrameInput :: struct {
  x_axis : f32,
  y_axis : f32,

  dash_press : bool,
  jump_press : bool,
}

get_player_input :: proc() -> FrameInput{
  input_data := FrameInput {}

  gamepad := ctx.settings.gamepad_index
  
  if app.is_gamepad_connected(gamepad) {

    left_axis := [2]f32 {}

    left_axis.x = app.get_gamepad_axis(gamepad, .Left_X)
    left_axis.y = app.get_gamepad_axis(gamepad, .Left_Y)

    input_data.dash_press = app.on_gamepad_button_down(gamepad, .X)

    input_data.x_axis = left_axis.x
    input_data.y_axis = left_axis.y
    input_data.jump_press = app.on_gamepad_button_down(gamepad, .A)
  } else {
    if app.is_key_pressed(.Left) && !app.is_key_pressed(.Right) {
      input_data.x_axis = -1.0
    }
    if !app.is_key_pressed(.Left) && app.is_key_pressed(.Right) {
      input_data.x_axis = 1.0
    }

    if app.is_key_pressed(.Down) && !app.is_key_pressed(.Up) {
      input_data.y_axis = 1.0
    }
    if !app.is_key_pressed(.Down) && app.is_key_pressed(.Up) {
      input_data.y_axis = -1.0
    }

    input_data.dash_press = app.on_key_down(.Left_Shift)
    input_data.jump_press = app.on_key_down(.Space)
  }

  return input_data;
}


control_player :: proc(entity : ^Entity, delta_time: f32) {
  input_data := get_player_input()
  axis_mag := input_data.x_axis * input_data.x_axis + input_data.y_axis * input_data.y_axis

  if entity.dashing {
    entity.color = draw.color(0xd3869b)
    entity.dash_timer -= delta_time
    entity.dashing = entity.dash_timer > 0.0
    entity.velocity -= entity.velocity * delta_time * 10
  } else {
    entity.color = draw.color(0xffffff)
    if entity.position.y >= 0 {
      target_velocity_x := input_data.x_axis * 300

      if abs(input_data.x_axis) > 0.1 {
        entity.velocity.x += (target_velocity_x - entity.velocity.x) * delta_time * 50
      } else {
        entity.velocity.x -= entity.velocity.x * delta_time * 10
      }

      if input_data.jump_press {
        entity.velocity.y = -400
      }

    } else {
      target_velocity_x := input_data.x_axis * 200
      entity.velocity.x += (target_velocity_x - entity.velocity.x) * delta_time * 4

      if input_data.dash_press && axis_mag > 0.1 {
        entity.dashing = true
        entity.dash_timer = 0.35
        entity.velocity = {input_data.x_axis, input_data.y_axis} * 1400
      }
    }

    if entity.position.y < 0 {
      entity.velocity.y += 980 * delta_time
    }
  }

  if entity.position.y > 0 {
    entity.velocity.y = 0
    entity.position.y = 0
  }
}
