package user

import "core:fmt"

player_system :: proc(delta_time : f32) {
  fmt.print("player_system", delta_time)
}
