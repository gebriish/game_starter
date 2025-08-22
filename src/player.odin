package main

import "core:fmt"

import "engine:app"
import "engine:draw"

FrameInput :: struct {
  x_axis : f32,
  y_axis : f32,

  dash_ready : bool,
  dash_confirm : bool,
  jump_press : bool,
}

get_player_input :: proc() -> FrameInput{
  input_data := FrameInput {}

  gamepad := ctx.settings.gamepad_index
  
  // Gamepad Controls
  left_axis := [2]f32 {}

  left_axis.x = app.get_gamepad_axis(gamepad, .Left_X)
  left_axis.y = app.get_gamepad_axis(gamepad, .Left_Y)


  input_data.x_axis = left_axis.x
  input_data.y_axis = left_axis.y

  input_data.jump_press |= app.on_gamepad_button_down(gamepad, .A)
  input_data.dash_ready |= app.is_gamepad_button_pressed(gamepad, .X)
  input_data.dash_confirm |= app.on_gamepad_button_up(gamepad, .X)


  // Keyboard controls
  if app.is_key_pressed(.A) && !app.is_key_pressed(.D) {
    input_data.x_axis = -1.0
  }
  if !app.is_key_pressed(.A) && app.is_key_pressed(.D) {
    input_data.x_axis = 1.0
  }

  if app.is_key_pressed(.S) && !app.is_key_pressed(.W) {
    input_data.y_axis = 1.0
  }
  if !app.is_key_pressed(.S) && app.is_key_pressed(.W) {
    input_data.y_axis = -1.0
  }

  input_data.dash_ready |= app.is_key_pressed(.Left_Shift)
  input_data.dash_confirm |= app.on_key_up(.Left_Shift)
  input_data.jump_press |= app.on_key_down(.Space)

  return input_data;
}


control_player :: proc(entity : ^Entity, delta_time: f32) {
  input_data := get_player_input()
  axis_mag := input_data.x_axis * input_data.x_axis + input_data.y_axis * input_data.y_axis

  dash_ready := !entity.dashing && input_data.dash_ready
  set_timescale(dash_ready ? 0.5 : 1.0)
  if input_data.dash_ready {
    entity.color = draw.color(0xd3869b)
  } else {
    entity.color = draw.color(0xffffff)
  }

  if entity.dashing {
    entity.color = draw.color(0xfb4934)
    entity.dash_timer -= delta_time
    entity.dashing = entity.dash_timer > 0.0
    entity.velocity -= entity.velocity * delta_time * 10
  } else {
    target_velocity_x := input_data.x_axis * 700
    if entity.position.y >= 0 {

      if abs(input_data.x_axis) > 0.1 {
        entity.velocity.x += (target_velocity_x - entity.velocity.x) * delta_time * 50
      } else {
        entity.velocity.x -= entity.velocity.x * delta_time * 10
      }

    } else {
      entity.velocity.x += (target_velocity_x - entity.velocity.x) * delta_time * 10

      if input_data.dash_confirm && axis_mag > 0.1 {
        entity.dashing = true
        entity.dash_timer = 0.35
        entity.velocity = {input_data.x_axis, input_data.y_axis} * 1800
      }

      gravity :f32= 1200.0
      if entity.velocity.y > 0 {
        gravity *= 4.74
      }
      entity.velocity.y += gravity * delta_time
    }

    if input_data.jump_press {
      entity.velocity.y = -500
    }
  }

  if entity.position.y > 0 {
    entity.velocity.y = 0
    entity.position.y = 0
  }
}
