package app

import "vendor:glfw"

@(private = "file") _key_states : [glfw.KEY_LAST + 1] u8 = 0
@(private = "file") _mouse_button_states : [glfw.MOUSE_BUTTON_LAST + 1] u8 = 0

get_cursor_pos :: proc() -> [2]f32 
{
  x, y := glfw.GetCursorPos(_app_state.glfw_handle)
  return {cast(f32) x, cast(f32) y}
}

is_key_pressed :: proc(keycode : i32) -> bool
{
  return (_key_states[keycode] & 1 != 0) && (_key_states[keycode] >> 1 & 1 == 0)
}

is_key_released :: proc(keycode : i32) -> bool
{
  return (_key_states[keycode] & 1 == 0) && (_key_states[keycode] >> 1 & 1 != 0)
}

is_key_down :: proc(keycode : i32) -> bool
{
  return _key_states[keycode] & 1 != 0
}

is_mouse_down :: proc(button : i32) -> bool 
{
  return _mouse_button_states[button] & 1 != 0
}

is_mouse_pressed :: proc(button : i32) -> bool 
{
  return  (_mouse_button_states[button] & 1 != 0) && (_mouse_button_states[button] >> 1 & 1 == 0)
}

is_mouse_released :: proc(button : i32) -> bool 
{
  return  (_mouse_button_states[button] & 1 == 0) && (_mouse_button_states[button] >> 1 & 1 != 0)
}

@(private) input_update_frame :: proc() 
{
  for i in 0..<len(_key_states) {
    state := &_key_states[i]
    state^ = state^ << 1
    if glfw.GetKey(_app_state.glfw_handle, cast(i32) i) == glfw.PRESS {
      state^ |= 1
    }
  }

  for i in 0..<len(_mouse_button_states) {
    state := &_mouse_button_states[i]
    state^ = state^ << 1
    if glfw.GetMouseButton(_app_state.glfw_handle, cast(i32) i) == glfw.PRESS {
      state^ |= 1
    }
  }
}
