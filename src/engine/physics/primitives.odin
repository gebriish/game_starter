package physics

BoxCollider :: struct {
  offset : vec2,
  half_size : vec2,
}

CircleCollider :: struct {
  offset : vec2,
  radius : f32,
}

Collider :: union {
  BoxCollider, 
  CircleCollider,
}

Ray :: struct {
  from : vec2,
  to : vec2
}

RayHit :: struct {
  normal : vec2,
  t : f32,
  hit_point : vec2,
}

