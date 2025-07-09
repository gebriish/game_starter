package app

import "base:runtime"
import "core:fmt"
import "vendor:glfw"

import gl "vendor:OpenGL"

import "engine:render"

WINDOW_HINT_NONE      :: 0
WINDOW_HINT_RESIZABLE :: 1 << 0
WINDOW_HINT_MAXIMIZED :: 1 << 1
WINDOW_HINT_DECORATED :: 1 << 2

@(private) _app_state : struct {
  glfw_handle : glfw.WindowHandle,
  frame_timestamp : f32,
  delta_time : f32,

  resize_callback : proc (x, y : i32),
}

// This is the entire Application runtime
run :: proc (
  window_x : i32,
  window_y : i32,
  title : cstring,
  hint_flags : u32 = WINDOW_HINT_NONE,
  init_proc : proc(),
  frame_proc : proc(),
  shutdown_proc : proc(),
  resize_proc :  proc (x, y : i32),
) {

  if !glfw.Init() {
    fmt.println("Failed to Initialize GLFW")
    return
  }

  glfw.WindowHint(glfw.RESIZABLE, hint_flags & WINDOW_HINT_RESIZABLE != 0)
  glfw.WindowHint(glfw.MAXIMIZED, hint_flags & WINDOW_HINT_MAXIMIZED != 0)
  glfw.WindowHint(glfw.DECORATED, hint_flags & WINDOW_HINT_DECORATED != 0)
  glfw.WindowHint(glfw.SAMPLES, 4)

  window := glfw.CreateWindow(
    window_x,
    window_y,
    title,
    nil, nil
  )

  _app_state.glfw_handle = window
  _app_state.resize_callback = resize_proc

  glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

  if window == nil {
    fmt.println("Failed to create GLFWwindow")
    return
  }

  glfw.MakeContextCurrent(window)
  glfw.SwapInterval(0)

  render.init()

  init_proc()
  
  last_frame_timestamp : f32 = cast(f32) glfw.GetTime()
  for !glfw.WindowShouldClose(window) {
    _app_state.frame_timestamp = cast(f32) glfw.GetTime()
    _app_state.delta_time = _app_state.frame_timestamp - last_frame_timestamp
    last_frame_timestamp = _app_state.frame_timestamp

    gl.ClearColor(0.0, 0.0, 0.0, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    input_update_frame()
    frame_proc()

    glfw.SwapBuffers(window)
    glfw.PollEvents()
  }

  shutdown_proc()
}

framebuffer_size_callback :: proc "c" (window : glfw.WindowHandle, width, height : i32)
{
  context = runtime.default_context()
  _app_state.resize_callback(width, height)
}

get_resolution :: proc() -> [2]f32 {
  x, y := glfw.GetWindowSize(_app_state.glfw_handle)
  return {cast(f32) x, cast(f32) y}
}

