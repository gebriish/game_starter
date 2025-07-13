package app
import "base:runtime"
import "vendor:glfw"

_key_states : [glfw.KEY_LAST + 1] u8 = 0
_mouse_button_states : [glfw.MOUSE_BUTTON_LAST + 1] u8 = 0
_mouse_scroll : [2]f32

get_cursor_pos :: proc() -> [2]f32 
{
  x, y := glfw.GetCursorPos(_app_state.glfw_handle)
  return {cast(f32) x, cast(f32) y}
}

is_key_pressed :: proc(keycode : i32) -> bool
{
  return _key_states[keycode] & 1 != 0
}

is_key_up :: proc(keycode : i32) -> bool
{
  return (_key_states[keycode] & 1 == 0) && (_key_states[keycode] >> 1 & 1 != 0)
}

is_key_down :: proc(keycode : i32) -> bool
{
  return (_key_states[keycode] & 1 != 0) && (_key_states[keycode] >> 1 & 1 == 0)
}

is_mouse_down :: proc(button : i32) -> bool 
{
  return  (_mouse_button_states[button] & 1 != 0) && (_mouse_button_states[button] >> 1 & 1 == 0)
}

is_mouse_pressed :: proc(button : i32) -> bool 
{
  return _mouse_button_states[button] & 1 != 0
}

is_mouse_up :: proc(button : i32) -> bool 
{
  return  (_mouse_button_states[button] & 1 == 0) && (_mouse_button_states[button] >> 1 & 1 != 0)
}

get_mouse_scroll :: proc() -> [2]f32 
{
  return _mouse_scroll
}

_input_update_frame :: proc() 
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
  
  _mouse_scroll = 0
}

_input_scroll_callback :: proc "c" (window : glfw.WindowHandle, x, y : f64)
{
  context = runtime.default_context()
  _mouse_scroll = {f32(x), f32(y)}
}
