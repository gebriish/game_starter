package app

KeySet :: bit_set[KeyCode]
MouseSet :: bit_set[MouseCode; u8]

input_state : InputState
InputState :: struct {
  keys_current : KeySet,
  keys_prev : KeySet,

  mouse_current : MouseSet,
  mouse_prev : MouseSet,

  cursor_current : [2]f32,
  cursor_prev : [2]f32,

  scroll : [2]f32,

  char_stream : rune,
  had_char_input : b32,
}

is_key_pressed :: proc(keycode : KeyCode) -> bool {
  using input_state
  return keycode in keys_current
}

on_key_up :: proc(keycode : KeyCode) -> bool {
  using input_state
  return (keycode not_in keys_current) && (keycode in keys_prev)
}

on_key_down :: proc(keycode : KeyCode) -> bool {
  using input_state
  return (keycode in keys_current) && (keycode not_in keys_prev)
}

is_mouse_pressed :: proc(button : MouseCode) -> bool {
  using input_state
  return button in mouse_current
}

on_mouse_up :: proc(button : MouseCode) -> bool {
  using input_state
  return (button not_in mouse_current) && (button in mouse_prev)
}

on_mouse_down :: proc(button : MouseCode) -> bool {
  using input_state
  return (button in mouse_current) && (button not_in mouse_prev)
}

cursor_pos :: proc() -> [2]f32 {
  return input_state.cursor_current
}

cursor_delta :: proc() -> [2]f32 {
  return input_state.cursor_current - input_state.cursor_prev
}

get_scroll :: proc() -> [2]f32 {
  return input_state.scroll
}

character_stream :: proc() -> (rune,bool) {
  return input_state.char_stream, bool(input_state.had_char_input)
}
