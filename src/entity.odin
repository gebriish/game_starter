package user

Entity :: struct {
  position : Position,
  size : Size,
  mask : ComponentMask,
}

GameSystem :: #type proc(delta_time : f32)

ColliderType :: enum {
  AABB,
  Circle,
  Capsule,
}

Collider :: struct {
  type : ColliderType,
  offset : Vec2,
  using _data : struct #raw_union {
    aabb : struct { half_size : Vec2 },
    capsule : struct { radius, height : f32},
    circle : struct { radius : f32 },
  }
}

ComponentType :: enum {
  None = 0,
  Player,
  Collider,
  Rigidbody,
}

ComponentMask :: u32

instantiate_entity :: proc(position, size : Vec2, mask : ComponentMask) {
  e : Entity = {
    position = position,
    size = size,
    mask = mask,
  }
}
