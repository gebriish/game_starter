package app

import "base:runtime"

import "core:fmt"
import "core:strings"
import "core:time"

import "vendor:glfw" /* GLFW Usage should be isolated in this file */

import "engine:draw"

WindowHint :: enum {
  None = 0,
  Resizable = 1 << 0,
  Maximized = 1 << 1,
  Decorated = 1 << 2,
  VSync     = 1 << 3,
}

CursorMode :: enum {
  Normal = 0,
  Hidden,
  Disabled,
  Captured,
}

app_state : AppState
AppState :: struct {
  glfw_handle : glfw.WindowHandle,
  window_x, window_y : i32,
  resize_pending : bool, 
}

run :: proc(
  width, height : i32,
  title : cstring,
  flags : WindowHint = .Decorated | .Resizable,
  init_proc : proc() = nil,
  frame_proc : proc(f32),
  shutdown_proc : proc() = nil,
  resize_proc : proc(x, y : i32) = nil,
) {
  if !glfw.Init() {
    fmt.println("Failed to initialize GLFW")
    return
  }

  glfw.WindowHint(glfw.RESIZABLE, flags & .Resizable != .None)
  glfw.WindowHint(glfw.MAXIMIZED, flags & .Maximized != .None)
  glfw.WindowHint(glfw.DECORATED, flags & .Decorated != .None)


  window := glfw.CreateWindow(width, height, title, nil, nil)
  if window == nil {
    fmt.println("Failed to create GLFWwindow")
    return
  }
  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(flags & .VSync == .None ? 0 : 1)

  app_state.glfw_handle = window
  app_state.window_x = width
  app_state.window_y = height

  last_time : = cast(f32) glfw.GetTime()

  setup_callbacks(window)

  draw.render_init(glfw.gl_set_proc_address)
  draw._resize_target(width, height)

  if init_proc != nil {
    init_proc()
  }

  for !glfw.WindowShouldClose(window) {
    current_time := cast(f32) glfw.GetTime()
    delta_time := current_time - last_time
    last_time = current_time

    { // input state updating
      using input_state
    
      keys_prev = keys_current
      keys_current = {}

      mouse_prev = mouse_current
      mouse_current = {}
      scroll = {}

      had_char_input = false 

      glfw.PollEvents()

      x, y := glfw.GetCursorPos(window)
      cursor_prev = cursor_current
      cursor_current = {f32(x), f32(y)}

      for k in KeyCode {
        if glfw.GetKey(window, cast(i32)_get_platfrom_keycode(k)) == glfw.PRESS {
          keys_current += {k}
        }
      }

      for m in MouseCode {
        if glfw.GetMouseButton(window, cast(i32) m) == glfw.PRESS {
          mouse_current += {m}
        }
      }
    }

    if app_state.resize_pending && resize_proc != nil {
      resize_proc(app_state.window_x, app_state.window_y)
      app_state.resize_pending = false
    }

    frame_proc(delta_time)

    glfw.SwapBuffers(window)
  }

  if shutdown_proc != nil {
    shutdown_proc()
  }
}

_get_platfrom_keycode :: #force_inline proc(code : KeyCode) -> u32 {
  switch code { // glfw keycodes
    case .SPACE         : return 32
    case .APOSTROPHE    : return 39  
    case .COMMA         : return 44  
    case .MINUS         : return 45  
    case .PERIOD        : return 46  
    case .SLASH         : return 47  
    case .SEMICOLON     : return 59  
    case .EQUAL         : return 61  
    case .LEFT_BRACKET  : return 91  
    case .BACKSLASH     : return 92  
    case .RIGHT_BRACKET : return 93  
    case .GRAVE_ACCENT  : return 96  
    case .WORLD_1       : return 161 
    case .WORLD_2       : return 162 
    case .ZERO  : return 48
    case .ONE   : return 49
    case .TWO   : return 50
    case .THREE : return 51
    case .FOUR  : return 52
    case .FIVE  : return 53
    case .SIX   : return 54
    case .SEVEN : return 55
    case .EIGHT : return 56
    case .NINE  : return 57
    case .A : return 65
    case .B : return 66
    case .C : return 67
    case .D : return 68
    case .E : return 69
    case .F : return 70
    case .G : return 71
    case .H : return 72
    case .I : return 73
    case .J : return 74
    case .K : return 75
    case .L : return 76
    case .M : return 77
    case .N : return 78
    case .O : return 79
    case .P : return 80
    case .Q : return 81
    case .R : return 82
    case .S : return 83
    case .T : return 84
    case .U : return 85
    case .V : return 86
    case .W : return 87
    case .X : return 88
    case .Y : return 89
    case .Z : return 90
    case .ESCAPE       : return 256
    case .ENTER        : return 257
    case .TAB          : return 258
    case .BACKSPACE    : return 259
    case .INSERT       : return 260
    case .DELETE       : return 261
    case .RIGHT        : return 262
    case .LEFT         : return 263
    case .DOWN         : return 264
    case .UP           : return 265
    case .PAGE_UP      : return 266
    case .PAGE_DOWN    : return 267
    case .HOME         : return 268
    case .END          : return 269
    case .CAPS_LOCK    : return 280
    case .SCROLL_LOCK  : return 281
    case .NUM_LOCK     : return 282
    case .PRINT_SCREEN : return 283
    case .PAUSE        : return 284
    case .F1  : return 290
    case .F2  : return 291
    case .F3  : return 292
    case .F4  : return 293
    case .F5  : return 294
    case .F6  : return 295
    case .F7  : return 296
    case .F8  : return 297
    case .F9  : return 298
    case .F10 : return 299
    case .F11 : return 300
    case .F12 : return 301
    case .F13 : return 302
    case .F14 : return 303
    case .F15 : return 304
    case .F16 : return 305
    case .F17 : return 306
    case .F18 : return 307
    case .F19 : return 308
    case .F20 : return 309
    case .F21 : return 310
    case .F22 : return 311
    case .F23 : return 312
    case .F24 : return 313
    case .F25 : return 314
    case .KP_0 : return 320
    case .KP_1 : return 321
    case .KP_2 : return 322
    case .KP_3 : return 323
    case .KP_4 : return 324
    case .KP_5 : return 325
    case .KP_6 : return 326
    case .KP_7 : return 327
    case .KP_8 : return 328
    case .KP_9 : return 329
    case .KP_DECIMAL  : return 330
    case .KP_DIVIDE   : return 331
    case .KP_MULTIPLY : return 332
    case .KP_SUBTRACT : return 333
    case .KP_ADD      : return 334
    case .KP_ENTER    : return 335
    case .KP_EQUAL    : return 336
    case .LEFT_SHIFT    : return 340
    case .LEFT_CONTROL  : return 341
    case .LEFT_ALT      : return 342
    case .LEFT_SUPER    : return 343
    case .RIGHT_SHIFT   : return 344
    case .RIGHT_CONTROL : return 345
    case .RIGHT_ALT     : return 346
    case .RIGHT_SUPER   : return 347
    case .MENU          : return 348
    case : return 0
  }
}

setup_callbacks :: proc(window : glfw.WindowHandle) {
  glfw.SetScrollCallback(window, proc "c" (window: glfw.WindowHandle, x, y: f64) {
    context = runtime.default_context()
    using input_state
    scroll = { f32(x), f32(y) }
  })

  glfw.SetCharCallback(window, proc "c" (window: glfw.WindowHandle, codepoint : rune) {
    context = runtime.default_context()
    input_state.char_stream = codepoint
    input_state.had_char_input = true
  })

  glfw.SetFramebufferSizeCallback(window, proc "c" (window : glfw.WindowHandle, x, y : i32) {
    context = runtime.default_context()
    draw._resize_target(x, y)
    app_state.window_x = x
    app_state.window_y = y
    app_state.resize_pending = true
  })
}

get_seconds :: proc() -> f32 {
  return f32(glfw.GetTime())
}

get_resolution :: proc() -> vec2 {
  return {f32(app_state.window_x), f32(app_state.window_y)}
}

cursor_mode :: proc(mode : CursorMode) {
  glfw_cursormode : i32
  switch mode {
  case .Normal   : glfw_cursormode = glfw.CURSOR_NORMAL
  case .Hidden   : glfw_cursormode = glfw.CURSOR_HIDDEN
  case .Disabled : glfw_cursormode = glfw.CURSOR_DISABLED
  case .Captured : glfw_cursormode = glfw.CURSOR_CAPTURED
  }
  glfw.SetInputMode(app_state.glfw_handle, glfw.CURSOR, glfw_cursormode)
}

pixels_to_ndc :: proc(pos : vec2) -> vec2 {
  ndc := pos / {f32(app_state.window_x), f32(app_state.window_y)}
  ndc = ndc * 2.0 - 1.0
  ndc.y *= -1
  return ndc
}


pixels_to_world :: proc(pixels : vec2, coord_space : draw.CoordSpace) -> vec2 {
  ndc := pixels_to_ndc(pixels)
  world := draw.ndc_to_world(coord_space, ndc)
  return world
}
