package main



Entity :: struct {
  position : vec2,
  size : vec2,
  pivot : Pivot,
  color : vec4,

  slot_free : bool,
  free_next : EntityHandle,

  
  velocity : vec2,
}


