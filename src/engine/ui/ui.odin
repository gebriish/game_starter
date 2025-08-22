package ui

MAX_CONTAINERS :: 2048

UI_Rect :: struct {
  x, y : f32,
  width, height : f32,
}

UI_Padding :: struct {
  left : f32,
  top : f32,
  right : f32,
  bottom : f32,
}

UI_LayoutDir :: enum u8 {
  Row = 0,
  Column
}

UI_Alignment :: enum u8 {
  Left = 0,
  Center = 1,
  Right = 2,
  Top = Left,
  Bottom = Right
}

UI_Config :: struct {
  padding : UI_Padding,
}

UI_Box :: struct {
  outer : UI_Rect,
  inner : UI_Rect,
  using _config : UI_Config,
}

UI_Context :: struct {
  flat_list : [MAX_CONTAINERS]UI_Box,
  container_count : u32, 
}

open_container :: proc(config : UI_Config) {
}

close_container :: proc() {
}

