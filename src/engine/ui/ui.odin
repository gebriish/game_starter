package ui

import "core:fmt"


_MAX_ELEMENTS :: 4096
_INVALID_ID   :: -1


UI_Id :: i32

UI_Position :: union { [2]f32 }

UI_SizeAxis :: struct {
  value : f32,
  type : enum { Fixed, Percent, Fill, Grow }
}

fixed :: proc(val : f32) -> UI_SizeAxis { return {value = val, type = .Fixed}}
percent :: proc(val : f32) -> UI_SizeAxis { return {value = val, type = .Percent}}
fill :: proc() -> UI_SizeAxis { return {value = 0, type = .Fill}}
grow :: proc() -> UI_SizeAxis { return {value = 0, type = .Grow}}

UI_Size :: struct {
  width, height : UI_SizeAxis,
}

UI_Padding :: struct {
  left, top, right, bottom : f32
}

UI_Config :: struct {
  pos : UI_Position,
  size : UI_Size,
  layout_direction : enum { Horizontal, Vertical },
  padding : UI_Padding,
  child_gap : f32,
  is_container : bool,
}

UI_Element :: struct {
  id : UI_Id,
  parent, child : UI_Id,
  sibling : UI_Id,

  using config : UI_Config,
  _layout_cursor : f32,
}

UI_Context :: struct {
  pointer : struct {
    position, _last_position : [2]f32,
    down, _last_down: bool,
  },

  flat_elements : [_MAX_ELEMENTS] UI_Element,
  open_element_id : UI_Id,
  num_elements : u32,

  draw_commands : [_MAX_ELEMENTS] UI_DrawCmd,

  layout_dimensions : [2]f32,
  open_element : UI_Id,
}
@(private)_ctx : ^UI_Context

create :: proc()
{
  if _ctx != nil {
    cleanup()
  }

  _ctx := new(UI_Context)
  _ctx.open_element_id = _INVALID_ID
}

cleanup :: proc() 
{
  if _ctx == nil do return

  free(_ctx)
  _ctx = nil
}

set_pointer :: proc(position : [2]f32, down : bool)
{
  _ctx.pointer._last_position = _ctx.pointer.position
  _ctx.pointer.position = position
  _ctx.pointer._last_down = _ctx.pointer.down
  _ctx.pointer.down = down
}

begin_frame :: proc(dimensions : [2]f32)
{
  _ctx.layout_dimensions = dimensions
  _ctx.num_elements = 0
  _ctx.open_element_id = _INVALID_ID
  
  open_element({
    pos = [2]f32 {0, 0},
    size = {fixed(dimensions.x), fixed(dimensions.y)},
    layout_direction = .Horizontal,
    padding = {0, 0, 0, 0},
    is_container = true
  })
}

end_frame :: proc()
{
  close_element()

  assert(_ctx.open_element < 0, "Forgot to close elements")
}

open_element :: proc(config : UI_Config)
{
  parent  := _get_open_element()
  element := &_ctx.flat_elements[_ctx.num_elements]

  element^ = UI_Element {
    id = cast(UI_Id) _ctx.num_elements,
    parent = _INVALID_ID,
    child = _INVALID_ID,
    sibling = _INVALID_ID,
    config = config,
  }

  if parent == nil {
    return
  }
  else {
    element.parent = parent.id
    element.sibling = parent.child
    parent.child = element.id

    padding := [4]f32 {parent.padding.left, parent.padding.top, parent.padding.right, parent.padding.bottom }

    /*
    size : [2]f32 = {
      _resolve_size(config.size.width, parent.size.width.value, padding.xz, parent._layout_cursor - parent.pos.x),
      _resolve_size(config.size.height, parent.size.height.value, padding.yw, parent._layout_cursor - parent.pos.y),
    }
    */

    size_resolved : [2]f32
    pos_resolved : [2]f32

    switch parent.layout_direction {
    case .Horizontal :
      pos_resolved.y = padding.y
      pos_resolved.x = padding.x + parent._layout_cursor
      parent._layout_cursor = pos_resolved.x + size_resolved.x + parent.child_gap
    case .Vertical :
      pos_resolved.x = padding.x
      pos_resolved.y = padding.y + parent._layout_cursor
      parent._layout_cursor = pos_resolved.y + size_resolved.y + parent.child_gap
    }
  
    element.pos = pos_resolved
    element.size = {
      {value = size_resolved.x, type = .Fixed},
      {value = size_resolved.y, type = .Fixed},
    }
  }

  _ctx.open_element_id = element.id
  _ctx.num_elements += 1
}

close_element :: proc()
{
  element := _get_open_element()
  if element.parent >= 0 {}
  _ctx.open_element = element.parent
}

_resolve_size :: proc(axis : UI_SizeAxis, parent : f32, bounds : [2]f32, cursor : f32) -> f32
{
  #partial switch axis.type {
  case .Fixed :
    return axis.value
  case .Percent : 
    return axis.value * (parent - (bounds[0] + bounds[1]))
  case .Fill :
    return (parent - cursor - bounds[1])
  case:
    return 0.0
  }
}

_pointer_down :: proc() -> bool { return _ctx.pointer.down && !_ctx.pointer._last_down }
_pointer_up :: proc() -> bool { return !_ctx.pointer.down && _ctx.pointer._last_down}
_pointer_pressed :: proc() -> bool { return _ctx.pointer.down }
_pointer_pos :: proc() -> [2]f32 { return _ctx.pointer.position }
_pointer_delta :: proc() -> [2]f32 { return _ctx.pointer.position - _ctx.pointer._last_position }
_get_open_element :: proc() -> ^UI_Element {
  if _ctx.open_element_id < 0 { return nil }
  return &_ctx.flat_elements[_ctx.open_element_id],
}

//----------------------------------------------
// Rendering
//----------------------------------------------

UI_DrawCmd :: struct {
  rect_pos : [2]f32,
  rect_size : [2]f32,
  rect_color : [4]f32,
  rect_corner_radii : [4]f32,
}

prepare_draw_commands :: proc() -> []UI_DrawCmd
{
  cmd_list : []UI_DrawCmd
  num_draw_commands := 0
  
  for i in 0..<_ctx.num_elements {
    element := &_ctx.flat_elements[i]
    draw_cmd := &_ctx.draw_commands[num_draw_commands]

    if element.is_container { continue }
  
    draw_cmd^ = {
      rect_pos = element.pos.([2]f32),
      rect_size = {element.size.width.value, element.size.height.value},
      rect_color = {1.0, 1.0, 1.0, 1.0},
      rect_corner_radii = 0.0
    }

    num_draw_commands += 1
  }

  cmd_list = _ctx.draw_commands[:num_draw_commands]
  return cmd_list
}

