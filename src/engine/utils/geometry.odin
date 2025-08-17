package utils

Pivot :: enum u32 {
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

/* 
  linear offset from topleft as origin
*/
pivot_offset :: proc(pivot : Pivot) -> vec2 {
  switch pivot {
  case .TopLeft: return {0,0}
  case .TopCenter: return {0.5,0}
  case .TopRight: return {1,0}

  case .MidLeft: return {0,0.5}
  case .MidCenter: return {0.5,0.5}
  case .MidRight: return {1,0.5}

  case .BottomLeft: return {0,1}
  case .BottomCenter: return {0.5,1}
  case .BottomRight: return {1,1}
  case : return {0,0}
  }
}

