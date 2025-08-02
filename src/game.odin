package user

SystemLookup := [ComponentType] GameSystem {
  .None = nil,
  .Player = player_system,
  .Collider = nil,
  .Rigidbody = nil,
}


GameState :: struct {
  entities : [dynamic] Entity, 
}

game_init :: proc(state : ^GameState)
{
}

game_update :: proc(state : ^GameState, delta_time : f32) 
{
}

game_shutdown :: proc(state : ^GameState) 
{
}
