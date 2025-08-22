#version 450 core
in VS_OUT {
  vec2 position;
  vec4 color;
  vec2 texcoords;
  float tex_id;
} fs_in;

out vec4 frag_color;

uniform sampler2D u_texslots[16];

void main() {
  int tex_id = int(fs_in.tex_id);
  vec4 sampled_texture = texture(u_texslots[tex_id], fs_in.texcoords);
  frag_color = fs_in.color;
  if (tex_id == 1) {
    float sdf_value = sampled_texture.a;
    float edge_width = fwidth(sdf_value) * 0.5;
    float alpha = smoothstep(0.5 - edge_width, 0.5 + edge_width, sdf_value);
    frag_color.a *= alpha;
  } else {
    frag_color *= sampled_texture;
  }
}
