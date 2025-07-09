package app

import "vendor:glfw"

get_frame_timestamp :: proc() -> f32
{
  return _app_state.frame_timestamp
}

get_seconds :: proc() -> f32
{
  return f32(glfw.GetTime())
}

get_delta_time :: proc() -> f32 
{
  return _app_state.delta_time
}
