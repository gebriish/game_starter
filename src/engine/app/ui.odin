package app

@(private="file") 
_ui_context : struct {
  dimensions : [2]f32,
}

ui_set_dimensions :: proc(dim : [2]f32)
{
  _ui_context.dimensions = dim
}

ui_set_pointer_state :: proc(pos : [2]f32, pressed : bool)
{
  ctx := &_ui_context
}



