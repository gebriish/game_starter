package main


Entity :: struct {
  position : vec2,
  size : vec2,
  pivot : Pivot,
  rotation : f32,

  color : vec4,

  slot_free : bool,
  free_next : EntityHandle,

  velocity : vec2,

  dash_timer : f32,
  dashing : b32,
}


