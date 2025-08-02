package user

import "core:encoding/hex"
import "core:math/rand"
import "core:math/linalg"
import "core:fmt"
import "core:time"
import "core:math"
import "core:strings"
import "core:mem"

import "engine:app"
import "engine:render"
import "engine:utils"
import "engine:ui"

main :: proc()
{
  app.run(
    window_x = 1000,
    window_y = 625,
    title = "game_starter",
    hint_flags = .Resizable | .Decorated,
    init_proc = core_app_init,
    frame_proc = core_app_frame,
  )
}

game_state : GameState

core_app_init :: proc()
{
  game_init(&game_state)
}

core_app_frame :: proc() 
{
  delta_time := app.get_delta_time()
  window := app.get_resolution()
  mouse_pos := app.get_mouse_pos()

  game_update(&game_state, delta_time)

  render.clear_frame({hexcode = 0x000000ff})
  render.wireframe_mode(app.is_key_pressed(.W))

  
  if render.push_pass(get_screen_space()) {
    render.push_rect(10,200,color = render.linear(0xebdbc7_ff))
  }

  free_all(context.temp_allocator)
}

get_world_space :: proc () -> render.CoordSpace
{
  res := app.get_resolution() * 0.5

  coord := render.CoordSpace {
    projection = linalg.matrix_ortho3d(
      -res.x, res.x, res.y, -res.y, -1, MAX_Z_LAYERS, false
    ),
    camera = linalg.matrix4_look_at(
      [3]f32 {0, 0, 0},
      [3]f32 {0, 0,-1},
      [3]f32 {0, 1, 0},
    )
  }
  coord.inverse = linalg.inverse(coord.projection * coord.camera)
  return coord
}

get_screen_space :: proc () -> render.CoordSpace
{
  res := app.get_resolution()

  coord := render.CoordSpace {
    projection = linalg.matrix_ortho3d(
      0, res.x, res.y, 0, -1, MAX_Z_LAYERS, false
    ),
    camera = linalg.matrix4_look_at(
      [3]f32 {0, 0, 0},
      [3]f32 {0, 0,-1},
      [3]f32 {0, 1, 0},
    )
  }
  coord.inverse = linalg.inverse(coord.projection * coord.camera)
  return coord
}
