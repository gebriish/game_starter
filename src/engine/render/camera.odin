package render

import "core:math"
import "core:math/linalg"

Camera :: struct {
  position : [2]f32,
  size     : [2]f32,
  scale    : f32,
  rotation : f32,
  clip_near, clip_far : f32,
  projection, view : matrix[4,4]f32,
}

update_view :: proc(camera : ^Camera)
{
  sin_val , cos_val := math.sin(camera.rotation), math.cos(camera.rotation)
  camera.view = linalg.matrix4_look_at(
    [3]f32{camera.position.x, camera.position.y, 0}, 
    [3]f32{camera.position.x, camera.position.y, -1}, 
    [3]f32{-sin_val ,cos_val , 0}
  )
}

update_proj :: proc(camera : ^Camera)
{
  half_size := camera.size * camera.scale * 0.5
  camera.projection = linalg.matrix_ortho3d(-half_size.x, half_size.x, -half_size.y, half_size.y, -1.0, 1000.0, false)
}

update_ui_proj :: proc(camera : ^Camera)
{
  camera.projection = linalg.matrix_ortho3d(0, camera.size.x, camera.size.y, 0, -1.0, 1000.0, false)
}

