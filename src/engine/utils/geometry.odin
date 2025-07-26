package utils

Pivot :: enum {
  TopLeft,
  TopCenter,
  TopRight,

  MidLeft,
  MidCenter,
  MidRight,

  BottomLeft,
  BottomCenter,
  BottomRight,
}

XAlignment :: enum {
  Left,
  Center,
  Right
}

YAlignment :: enum {
  Top,
  Middle,
  Bottom
}

pivot_scale :: proc(pivot : Pivot) -> [2]f32
{
  @(static, rodata) pivot_scales := [Pivot][2]f32 {
    .TopLeft = {0, 0},
    .TopCenter = {0.5, 0},
    .TopRight = {1, 0},

    .MidLeft = {0, 0.5},
    .MidCenter = {0.5, 0.5},
    .MidRight = {1, 0.5},

    .BottomLeft = {0, 1},
    .BottomCenter = {0.5, 1},
    .BottomRight = {1, 1},
  }
  return pivot_scales[pivot]
}

pivot_in_rect :: proc(position, size : [2]f32, pivot : Pivot) -> [2]f32
{
  offset := pivot_scale(pivot) * size
  return position + offset
}