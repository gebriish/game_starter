package app

KeySet :: bit_set[KeyCode; u128]
MouseSet :: bit_set[MouseCode; u8]
GamepadSet :: bit_set[GamepadCode; u16]

GamepadState :: struct {
  buttons_current : GamepadSet,
  buttons_prev : GamepadSet,
  axes : [GamepadAxis]f32,
  connected : bool,
}

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

  gamepads : [MAX_GAMEPADS]GamepadState,
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

//-- gamepad support --
is_gamepad_connected :: proc(gamepad_id: u32) -> bool {
  if gamepad_id < 0 || gamepad_id >= MAX_GAMEPADS { return false }
  return input_state.gamepads[gamepad_id].connected
}

is_gamepad_button_pressed :: proc(gamepad_id: u32, button: GamepadCode) -> bool {
  if !is_gamepad_connected(gamepad_id) {
    return false 
  }
  return button in input_state.gamepads[gamepad_id].buttons_current
}

on_gamepad_button_down :: proc(gamepad_id: u32, button: GamepadCode) -> bool {
  if !is_gamepad_connected(gamepad_id) do return false
    gamepad := &input_state.gamepads[gamepad_id]
    return (button in gamepad.buttons_current) && (button not_in gamepad.buttons_prev)
}

on_gamepad_button_up :: proc(gamepad_id: u32, button: GamepadCode) -> bool {
  if !is_gamepad_connected(gamepad_id) do return false
    gamepad := &input_state.gamepads[gamepad_id]
    return (button not_in gamepad.buttons_current) && (button in gamepad.buttons_prev)
}

get_gamepad_axis :: proc(gamepad_id: u32, axis: GamepadAxis) -> f32 {
  if !is_gamepad_connected(gamepad_id) do return 0.0
    return input_state.gamepads[gamepad_id].axes[axis]
}

get_gamepad_stick :: proc(gamepad_id: u32, left_stick: bool = true) -> [2]f32 {
  if !is_gamepad_connected(gamepad_id) do return {0, 0}

  if left_stick {
    return {
      input_state.gamepads[gamepad_id].axes[.Left_X],
      input_state.gamepads[gamepad_id].axes[.Left_Y]
    }
  } else {
    return {
      input_state.gamepads[gamepad_id].axes[.Right_X],
      input_state.gamepads[gamepad_id].axes[.Right_Y]
    }
  }
}

get_gamepad_triggers :: proc(gamepad_id: u32) -> [2]f32 {
  if !is_gamepad_connected(gamepad_id) do return {0, 0}
  return {
    input_state.gamepads[gamepad_id].axes[.Left_Trigger],
    input_state.gamepads[gamepad_id].axes[.Right_Trigger]
  }
}
