package ui


MAX_ELEMENTS :: 4096

UI_ID :: uint

UI_Config :: struct {
}

UI_Element :: struct {
  id : UI_ID,
  parent, child : UI_ID,
  sibling : UI_ID,
  config : UI_Config,
}

UI_Context :: struct {

  pointer : struct {
    position, _last_position : [2]f32,
    down, _last_down : bool,
  },

  logic_pass : bool,
}
@(private) _ctx : UI_Context

is_logic_pass :: #force_inline proc() { return _ctx.logic_pass }