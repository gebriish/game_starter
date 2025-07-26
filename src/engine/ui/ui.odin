package ui

import "base:runtime"

UI_ID :: distinct i32

UI_Box :: struct {
  id: UI_ID,
  parent: UI_ID,
  sibling: UI_ID,
  first_child: UI_ID,
  last_child: UI_ID,
}

UI_Size :: struct {
  width, height : struct {
    value : f32,
    type : enum { Fixed, Percent, Fill }
  }
}

UI_Config :: struct {
  size : UI_Size,
  padding : struct { left, top, right, bottom : f32 },
  direction : enum { LeftToRight, TopToBottom },
  child_gap : f32,
}

_ctx: UI_Context
UI_Context :: struct {
  flat_list: [MAX_ELEMENTS]UI_Box,
  num_elements: u32,
  open_element: UI_ID,
}

begin_layout :: proc(width, height : f32) {
  _ctx.num_elements = 0
  _ctx.open_element = -1
}

end_layout :: proc() {
}

open :: proc() -> UI_ID {
  if _ctx.num_elements >= MAX_ELEMENTS {
    return -1
  }

  next_id := UI_ID(_ctx.num_elements)
  parent_id := _ctx.open_element

  element := &_ctx.flat_list[_ctx.num_elements]
  element^ = UI_Box{
    id = next_id,
    parent = parent_id,
    sibling = -1,
    first_child = -1,
    last_child = -1,
  }

  if parent_id != -1 {
    parent := &_ctx.flat_list[parent_id]

    if parent.first_child == -1 {
      parent.first_child = next_id
      parent.last_child = next_id
    } else {
      last_child := &_ctx.flat_list[parent.last_child]
      last_child.sibling = next_id
      parent.last_child = next_id
    }
  }

  _ctx.num_elements += 1
  _ctx.open_element = next_id

  return next_id
}

close :: proc() {
  if _ctx.open_element != -1 {
    current := &_ctx.flat_list[_ctx.open_element]
    _ctx.open_element = current.parent
  }
}

print_tree :: proc(id: UI_ID = 0, depth: int = 0) {
  if id >= UI_ID(_ctx.num_elements) || id < 0 {
    return
  }

  element := &_ctx.flat_list[id]

  for i in 0..<depth {
    runtime.print_string("  ")
  }
  runtime.print_string("ID:")
  runtime.print_int(int(element.id))
  runtime.print_string(" Parent:")
  runtime.print_int(int(element.parent))
  runtime.print_string(" Sibling:")
  runtime.print_int(int(element.sibling))
  runtime.print_string(" FirstChild:")
  runtime.print_int(int(element.first_child))
  runtime.print_string(" LastChild:")
  runtime.print_int(int(element.last_child))
  runtime.print_string("\n")

  child_id := element.first_child
  for child_id != -1 {
    print_tree(child_id, depth + 1)
    child := &_ctx.flat_list[child_id]
    child_id = child.sibling
  }
}
