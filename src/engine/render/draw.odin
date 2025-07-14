package render

CoordSpace :: struct {
    projection : matrix[4,4]f32,
    camera : matrix[4,4]f32,
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
