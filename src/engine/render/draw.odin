package render

CoordSpace :: struct {
    projection, camera, inverse : matrix[4,4]f32
}

set_coord_space :: #force_inline proc(coord : CoordSpace) 
{
    _render_state.coord_space = coord
    upload_projection(&_render_state.coord_space)
    upload_view(&_render_state.coord_space)
}

@(deferred_out=set_coord_space)
push_coord_space :: proc(coord : CoordSpace) -> CoordSpace
{
    original := _render_state.coord_space
    set_coord_space(coord)
    return original
}

set_z_layer :: #force_inline proc(z : f32) 
{
    _render_state.z_position = z
}

@(deferred_out=set_z_layer)
push_z_layer :: proc(z : f32) -> f32 
{
    original := _render_state.z_position
    set_z_layer(z)
    return original
}

screen_to_world2d :: proc(cs: CoordSpace, coord: [2]f32, screen : [2]f32) -> [2]f32 
{
    ndc_x := (2.0 * coord.x / screen.x) - 1.0;
    ndc_y := 1.0 - (2.0 * coord.y / screen.y);

    ndc_pos := [4]f32{ndc_x, ndc_y, 0.0, 1.0};

    world_pos4 := cs.inverse * ndc_pos;

    if world_pos4.w != 0.0 {
        world_pos4 /= world_pos4.w;
    }

    return world_pos4.xy;
}
