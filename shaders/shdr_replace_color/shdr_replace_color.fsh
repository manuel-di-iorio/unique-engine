varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec3 u_col;

void main() {
	gl_FragColor = vec4(u_col, 1.0);
}
