package main

import "engine:physics"


EntityFlag :: enum u32 {
  Physics, 
  Sprite,
}

EntityFlagSet :: bit_set[EntityFlag; u32]

Entity :: struct {
  // Base entity properties
  position : vec2,
  size : vec2,
  rotation : f32,
  flags : EntityFlagSet,

  // Physics
  velocity : vec2,
  collider : physics.Collider,

  // Sprite
  color : vec4,


  // Player-specific
  dash_timer : f32,
  dashing : b32,

  // freelist
  slot_free : bool,
  free_next : EntityHandle,
}


