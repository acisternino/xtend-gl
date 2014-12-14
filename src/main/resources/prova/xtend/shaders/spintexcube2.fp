#version 150

uniform sampler2D tex;

in  vec2  frag_tex_coord;

out vec4  frag_color;

void main() {
    frag_color = texture( tex, frag_tex_coord );
}
