varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D s_map;

void main()
{
    gl_FragColor = v_vColour * texture2D(s_map, v_vTexcoord);
}
