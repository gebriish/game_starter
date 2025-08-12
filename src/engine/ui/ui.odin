package ui

import "core:slice/heap"
import "core:fmt"
import "core:math"

UI_ID :: distinct i32

_ctx: Context
Context :: struct {
  open_element: ^Box,

  flat_list: [MAX_ELEMENTS]Box,
  num_elements: u32,

  pointer : struct {
    x, y : f32,
    last_x, last_y : f32,
    down : b32,
    last_down :b32, 
  },

  hot_idx : u32,
  active_idx : u32,

  draw_commands : [MAX_ELEMENTS]DrawCmd,
}

Box :: struct {
  parent: ^Box,
  next : ^Box,
  first, last : ^Box,
  using _config : Config, /* embed */

  position : [2]f32,
  creation_idx : u32,
  cursor_position : [2]f32,
}


fixed :: proc(x : f32) -> SizeAxis { return {value = x, type = .Fixed }}
percent :: proc(x : f32) -> SizeAxis { return {value = x, type = .Perc }}
root_percent :: proc(x : f32) -> SizeAxis { return {value = x, type = .RootPerc }}
fit :: proc() -> SizeAxis { return { type = .Fit }}
fill :: proc() -> SizeAxis { return {type = .Fill}}

SizeAxis :: struct {
  value : f32,
  type : enum u32 {
    Fixed,
    Perc, // 0 -> 1 percent of parent's size
    RootPerc, // 0 -> percent of root element's size ( ie layout size )
    Fill,
    Fit,
  },
}

Size :: struct {
  width, height : SizeAxis
}

Layout :: enum u32 { Vertical, Horizontal }
Padding :: struct { left, top, right, bottom : f32 }

/*
  The elements with custom positioning are
  de-coupled from the ui layout algorithm, and the 
  'cursor' positioning.

  Ideally these elements are the only child of the parent, 
  like the parent is the main ui 'component'. 
*/

Config :: struct {
  size : Size,
  padding : Padding,
  direction : Layout,
  child_gap : f32,

  // visuals
  color : [4]f32, // r g b a (0 to 1) values
  radii : [4]f32, // clockwise from top left
  outline_color : [4]f32,
  outline : f32,

  is_container : b8,
}

set_pointer :: proc(x, y : f32, down : bool) {
  _ctx.pointer.last_x, _ctx.pointer.last_y = _ctx.pointer.x, _ctx.pointer.y
  _ctx.pointer.last_down = _ctx.pointer.down

  _ctx.pointer.x , _ctx.pointer.y = x, y
  _ctx.pointer.down = b32(down)
}

begin_layout :: proc(
  size : [2]f32,
  direction := Layout.Vertical,
  padding := Padding {5,5,5,5},
  child_gap :f32= 5
)
{
  _ctx.num_elements = 0
  _ctx.open_element = nil
  _ctx.hot_idx = 0
  _ctx.active_idx = 0

  open_box()
  config_box({
    size = {
      fixed(size.x),
      fixed(size.y)
    },
    padding = padding,
    direction = direction,
    child_gap = child_gap,
    is_container = true,
  })
}

end_layout :: proc() 
{
  close_box()
}

open_box :: proc() -> u32
{
  if _ctx.num_elements >= MAX_ELEMENTS {
    fmt.println("UI_Box overflow")
    return 0
  }

  parent := _ctx.open_element
  element := &_ctx.flat_list[_ctx.num_elements]
  element^ = Box{
    parent = parent,
    next = nil,
    first = nil,
    last = nil,
    cursor_position = {0, 0}, // Initialize cursor
    creation_idx = _ctx.num_elements,
  }
  if parent != nil {
    if parent.first == nil {
      parent.first = element
      parent.last = element
    } else {
      last_child := parent.last
      last_child.next = element
      parent.last = element
    }
  }
  _ctx.num_elements += 1
  _ctx.open_element = element
  return element.creation_idx
}

close_box :: proc() 
{
  if _ctx.open_element == nil {
    fmt.println("Repeated ui::close call")
    return
  }
  
  element := _ctx.open_element
  parent := element.parent
  
  if parent != nil {
    switch parent.direction {
    case .Horizontal:
      parent.cursor_position.x += element.size.width.value + parent.child_gap
      
      if parent.size.width.type == .Fit {
        if parent.first == element {
          parent.size.width.value = element.size.width.value + parent.padding.left + parent.padding.right
        } else {
          parent.size.width.value += element.size.width.value + parent.child_gap
        }
      }
      
      if parent.size.height.type == .Fit {
        content_height := element.size.height.value + parent.padding.top + parent.padding.bottom
        parent.size.height.value = math.max(parent.size.height.value, content_height)
      }
      
    case .Vertical:
      parent.cursor_position.y += element.size.height.value + parent.child_gap
      
      if parent.size.height.type == .Fit {
        if parent.first == element {
          parent.size.height.value = element.size.height.value + parent.padding.top + parent.padding.bottom
        } else {
          parent.size.height.value += element.size.height.value + parent.child_gap
        }
      }
      
      if parent.size.width.type == .Fit {
        content_width := element.size.width.value + parent.padding.left + parent.padding.right
        parent.size.width.value = math.max(parent.size.width.value, content_width)
      }
    }
  }
  
  pos := element.position
  size := [2]f32{element.size.width.value, element.size.height.value}
  pointer := [2]f32{_ctx.pointer.x, _ctx.pointer.y}

  if rect_vs_point(pos, size, pointer) {
    if _ctx.hot_idx == 0 || element.creation_idx >= _ctx.hot_idx {
      _ctx.hot_idx = element.creation_idx
      if _ctx.pointer.down { _ctx.active_idx = element.creation_idx }
    }
  }

  _ctx.open_element = parent
}

config_box :: proc(config : Config)
{
  if _ctx.open_element == nil { return }
  element := _ctx.open_element
  parent  := element.parent
  parent_pos := parent.position if parent != nil else {0,0}
  root := &_ctx.flat_list[0]
  element._config = config
  
  resolve_axis :: proc(axis: ^SizeAxis, parent_size, root_size, available_space, child_gap : f32) {
    #partial switch axis.type {
    case .Perc:
      axis.value = axis.value * parent_size - child_gap * 0.5
      axis.type = .Fixed
    case .RootPerc:
      axis.value = axis.value * root_size
      axis.type = .Fixed
    case .Fill:
      axis.value = available_space
      axis.type = .Fixed
    }
  }
  
  if parent != nil {
    parent_width := parent.size.width.value
    parent_height := parent.size.height.value
    root_width := root.size.width.value
    root_height := root.size.height.value
    
    available_width := parent_width - parent.padding.left - parent.padding.right - parent.cursor_position.x
    available_height := parent_height - parent.padding.top - parent.padding.bottom - parent.cursor_position.y
    
    resolve_axis(&element.size.width, parent_width - parent.padding.left - parent.padding.right, root_width, available_width, parent.child_gap)
    resolve_axis(&element.size.height, parent_height - parent.padding.top - parent.padding.bottom, root_height, available_height, parent.child_gap)
  }
  
  if parent != nil {
    switch parent.direction {
    case .Horizontal:
      element.position = [2]f32 {
        parent_pos.x + parent.padding.left + parent.cursor_position.x, 
        parent_pos.y + parent.padding.top
      }
    case .Vertical:
      element.position = [2]f32 {
        parent_pos.x + parent.padding.left, 
        parent_pos.y + parent.padding.top + parent.cursor_position.y
      }
    }
  }
  element.cursor_position = {0, 0}
}

content_region :: proc() -> [2]f32 
{
    if _ctx.open_element == nil { return {0, 0} }
    element := _ctx.open_element
    return {
        element.size.width.value - element.cursor_position.x - element.padding.right,
        element.size.height.value - element.cursor_position.y - element.padding.bottom
    }
}

rect_vs_point :: proc(pos, size: [2]f32, point: [2]f32) -> bool {
  end_point := pos + size;
  return pos.x < point.x && point.x < end_point.x &&
         pos.y < point.y && point.y < end_point.y;
}
