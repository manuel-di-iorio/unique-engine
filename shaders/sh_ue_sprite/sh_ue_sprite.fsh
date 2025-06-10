varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec3 u_ueModelPosition;
uniform vec3 u_ueCameraPosition;

uniform sampler2D s_map;

void main()
{
    gl_FragColor = v_vColour.rgba * texture2D(s_map, v_vTexcoord).rgba;
}
