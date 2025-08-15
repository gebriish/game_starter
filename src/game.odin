package main

import "core:fmt"

import "engine:draw"

EntityHandle :: u32

ctx : GameState
GameState :: struct {
  entities: [dynamic]Entity,
  free_list_head: EntityHandle,
  next_handle: EntityHandle,

  player_handle : EntityHandle,
  camera_position : vec2,
}

game_init :: proc() {
  ctx.entities = make([dynamic]Entity)
  ctx.free_list_head = 0
  ctx.next_handle = 1
  
  append(&ctx.entities, Entity{
    position = {0, 0},
    size = {0, 0},
    pivot = .MidCenter,
    slot_free = false, // Scratch is never free
    free_next = 0,
  })

  ctx.player_handle = create_entity()
  player := get_entity(ctx.player_handle)
  player.size = {32,64}
  player.pivot = .BottomCenter
  player.color = draw.color(0xebdbc7)

  floor := get_entity(create_entity())
  floor.size = {300,80}
  floor.pivot = .TopCenter
  floor.color = draw.color(0x282828)
}

game_update :: proc(delta_time : f32) {
  ctx.entities[0] = {}
 
  player_entity := get_entity(ctx.player_handle)
  control_player(player_entity, delta_time)


  for &entity in get_entities() {
    if entity.slot_free { continue }

    entity.position += entity.velocity * delta_time
  }
}

create_entity :: proc() -> EntityHandle {
  handle: EntityHandle
  
  if ctx.free_list_head != 0 {
    handle = ctx.free_list_head
    ctx.free_list_head = ctx.entities[handle].free_next
    ctx.entities[handle] = Entity {}
  } else {
    handle = EntityHandle(len(ctx.entities))
    append(&ctx.entities, Entity{})
  }
  
  return handle
}

free_entity :: proc(handle: EntityHandle) {
  if (
    handle == 0 || 
    handle >= EntityHandle(len(ctx.entities)) || 
    ctx.entities[handle].slot_free
  ) { return }
  
  entity := &ctx.entities[handle]
  
  entity.slot_free = true
  entity.free_next = ctx.free_list_head
  ctx.free_list_head = handle
}

get_entity :: proc(handle : EntityHandle) -> ^Entity {
  if handle >= EntityHandle(len(ctx.entities)) || ctx.entities[handle].slot_free {
    return &ctx.entities[0]
  }
  
  entity := &ctx.entities[handle]
  
  return entity
}

get_entities :: proc() -> []Entity {
  return ctx.entities[1:]
}
