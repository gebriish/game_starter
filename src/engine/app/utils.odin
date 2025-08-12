package app

import stbi "vendor:stb/image"

import "engine:draw"

load_texture :: proc(path : cstring) -> (draw.Texture, bool) {
  x, y, c : i32
  data := stbi.load(path, &x, &y, &c,0);
  return draw.Texture{&data[0], x, y, c}, data != nil
}

free_texture :: proc(data : rawptr) {
  stbi.image_free(data)
}
