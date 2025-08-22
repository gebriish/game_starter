package physics

import "core:math"

box_collider_values :: #force_inline proc(
  position :vec2, 
  collider : BoxCollider
) -> (min, max : vec2) {
  p0 := position + collider.offset
  return p0 - collider.half_size, p0 + collider.half_size
}

circle_collider_values :: #force_inline proc(
  position : vec2, 
  collider : CircleCollider
) -> (center : vec2, radius : f32) {
  return position + collider.offset, collider.radius
}

ray_vs_aabb :: proc(min, max : vec2, ray : Ray) -> (hit: RayHit, ok : bool) {
  dir := ray.to - ray.from
  
  inv_dir := vec2{
    dir.x == 0 ? math.INF_F32 : 1.0 / dir.x,
    dir.y == 0 ? math.INF_F32 : 1.0 / dir.y,
  }
  
  t1 := (min - ray.from) * inv_dir
  t2 := (max - ray.from) * inv_dir
  
  if t1.x > t2.x do t1.x, t2.x = t2.x, t1.x
  if t1.y > t2.y do t1.y, t2.y = t2.y, t1.y
  
  t_near := math.max(t1.x, t1.y)
  t_far := math.min(t2.x, t2.y)
  
  if t_near > t_far || t_far < 0 {
    return {}, false
  }
  
  t := t_near >= 0 ? t_near : t_far
  if t < 0 do return {}, false
  
  hit_point := ray.from + t * dir
  center := (min + max) * 0.5
  half_size := (max - min) * 0.5
  
  rel_pos := hit_point - center
  abs_rel := vec2{math.abs(rel_pos.x), math.abs(rel_pos.y)}
  
  normal := vec2{0, 0}
  if abs_rel.x / half_size.x > abs_rel.y / half_size.y {
    normal.x = rel_pos.x > 0 ? 1 : -1
  } else {
    normal.y = rel_pos.y > 0 ? 1 : -1
  }
  
  return RayHit{normal = normal, t = t, hit_point = hit_point}, true
}

ray_vs_circle :: proc(center : vec2, radius : f32, ray : Ray) -> (hit: RayHit, ok : bool) {
  dir := ray.to - ray.from
  dir_length := math.sqrt(dot(dir, dir))

  if dir_length == 0 do return {}, false

  dir_normalized := dir / dir_length
  to_center := center - ray.from

  proj_length := dot(to_center, dir_normalized)
  closest_point := ray.from + proj_length * dir_normalized

  dist_to_line := distance(center, closest_point)

  if dist_to_line > radius do return {}, false

  if dist_to_line == radius {
    t := proj_length / dir_length
    if t < 0 || t > 1 do return {}, false

    return RayHit{
      normal = normalize(closest_point - center),
      t = t,
      hit_point = closest_point,
    }, true
  }

  half_chord := math.sqrt(radius * radius - dist_to_line * dist_to_line)

  t1 := (proj_length - half_chord) / dir_length
  t2 := (proj_length + half_chord) / dir_length

  t := t1
  if t1 < 0 {
    t = t2
  }

  if t < 0 do return {}, false

  hit_point := ray.from + t * dir
  normal := normalize(hit_point - center)

  return RayHit{
    normal = normal,
    t = t,
    hit_point = hit_point,
  }, true
}


distance :: proc(a, b : vec2) -> f32 {
  diff := b - a
  return math.sqrt(dot(diff, diff))
}

dot :: proc(a, b : vec2) -> f32 {
  return a.x * b.x + a.y * b.y
}

normalize :: proc(v : vec2) -> vec2 {
  length := math.sqrt(dot(v, v))
  if length == 0 do return vec2{0, 0}
  return v / length
}
