package ui

DrawRect :: struct {
  pos, size : [2]f32,
  color, radii : [4]f32,
  outline_color : [4]f32,
  outline : f32,
}

DrawCmd :: union {
  DrawRect,
}

generate_draw_cmd :: proc() -> []DrawCmd {
  _ctx.draw_commands = {}
  cmd_count := 0
  
  if _ctx.num_elements > 0 {
    root := &_ctx.flat_list[0]
    traverse_for_drawing(root, &cmd_count)
  }
  
  return _ctx.draw_commands[:cmd_count]
}

traverse_for_drawing :: proc(box : ^UI_Box, cmd_count : ^int) {
  if box == nil || cmd_count^ >= MAX_ELEMENTS {
    return
  }
  
  if should_draw_box(box) {
    cmd := &_ctx.draw_commands[cmd_count^]
    cmd_count^ += 1
  
    cmd^ = DrawRect {
      pos = box.position,
      size = {
        box.size.width.value,
        box.size.height.value,
      },
      color = box.color,
      radii = box.radii,
      outline_color = box.outline_color,
      outline = box.outline,
    }
  }
  
  child := box.first
  for child != nil {
    traverse_for_drawing(child, cmd_count)
    child = child.next
  }
}

should_draw_box :: proc(box : ^UI_Box) -> bool {
  if box.color.a <= 0.0 { return false }
  if box.size.width.value <= 0 || box.size.height.value <= 0 { return false }
  if box.is_container { return false }
  
  //TODO : draw bounds checks
  return true
}
