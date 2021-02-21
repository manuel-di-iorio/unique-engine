function scr_model_create_mesh(hasTexture, hasNormals) {
	vertex_format_begin();
	vertex_format_add_position_3d();
	if (hasTexture) vertex_format_add_texcoord();
	if (hasNormals) vertex_format_add_normal();
	vertex_format_add_color();
	var format = vertex_format_end();

	var vbuff = vertex_create_buffer();
	vertex_begin(vbuff, format);	
	return vbuff;
}