package app
import "base:runtime"
import "vendor:glfw"

_input_state : InputState
InputState :: struct {
  keys : #sparse[KeyCode] u8,
  mouse_buttons : [MouseButton] u8,
  mouse_scroll : [2]f32,
  mouse_position : [2]f32,
  mouse_pos_last : [2]f32,
}

get_mouse_pos :: proc() -> [2]f32 
{
  return _input_state.mouse_position
}

get_mouse_delta :: proc() -> [2]f32 
{
  return _input_state.mouse_position - _input_state.mouse_pos_last
}

is_key_pressed :: proc(keycode : KeyCode) -> bool
{
  using _input_state
  return keys[keycode] & 1 != 0
}

on_key_up :: proc(keycode : KeyCode) -> bool
{
  using _input_state
  return (keys[keycode] & 1 == 0) && (keys[keycode] >> 1 & 1 != 0)
}

on_key_down :: proc(keycode : KeyCode) -> bool
{
  using _input_state
  return (keys[keycode] & 1 != 0) && (keys[keycode] >> 1 & 1 == 0)
}

on_mouse_down :: proc(button : MouseButton) -> bool 
{
  using _input_state
  return  (mouse_buttons[button] & 1 != 0) && (mouse_buttons[button] >> 1 & 1 == 0)
}

is_mouse_pressed :: proc(button : MouseButton) -> bool 
{
  using _input_state
  return mouse_buttons[button] & 1 != 0
}

on_mouse_up :: proc(button : MouseButton) -> bool 
{
  using _input_state
  return  (mouse_buttons[button] & 1 == 0) && (mouse_buttons[button] >> 1 & 1 != 0)
}

get_mouse_scroll :: proc() -> [2]f32 
{
  using _input_state
  return mouse_scroll
}

_input_update_frame :: proc() 
{
  using _input_state
  
  any_state := &keys[.ANY]
  any_state^ = any_state^ << 1

  for k in KeyCode {
    if k == .ANY { break }
    
    state := &keys[k]
    state^ = state^ << 1
    if glfw.GetKey(_app_state.glfw_handle, cast(i32) k) == glfw.PRESS {
      state^ |= 1
      any_state^ |= 1
    }
  }

  for b in MouseButton {
    state := &mouse_buttons[b]
    state^ = state^ << 1
    if glfw.GetMouseButton(_app_state.glfw_handle, cast(i32) b) == glfw.PRESS {
      state^ |= 1
    }
  }
  
  mouse_scroll = 0
  x, y := glfw.GetCursorPos(_app_state.glfw_handle)
  mouse_pos_last = mouse_position
  mouse_position = {f32(x), f32(y)}
}

_input_scroll_callback :: proc "c" (window : glfw.WindowHandle, x, y : f64)
{
  using _input_state
  context = runtime.default_context()
  mouse_scroll = {f32(x), f32(y)}
}
