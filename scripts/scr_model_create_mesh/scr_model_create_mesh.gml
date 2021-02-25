/** Define the formats */

// Color
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_color();
FORMAT_PC = vertex_format_end();

// Texture
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_texcoord();
vertex_format_add_color();
FORMAT_PTC = vertex_format_end();

// Texture
vertex_format_begin();
vertex_format_add_position_3d();
vertex_format_add_texcoord();
vertex_format_add_normal();
vertex_format_add_color();
FORMAT_PTXC = vertex_format_end();

function scr_model_create_mesh(hasTexture, hasNormals) {
	var format;
	if (hasTexture && hasNormals) {
		format = global.FORMAT_PTXC;
	} else if (hasTexture) {
		format = global.FORMAT_PTC;
	} else {
		format = global.FORMAT_PC;
	}

	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, format);	
	return vbuff;
}