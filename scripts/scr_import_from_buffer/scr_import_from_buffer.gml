/** Load a buffer file and return a new vertex buffer */
function scr_import_from_buffer(path) {
	vertex_format_begin(); 
	vertex_format_add_position_3d();
	vertex_format_add_texcoord();
	vertex_format_add_normal();
	vertex_format_add_color();
	var vformat = vertex_format_end();

	var buf = buffer_load(path);
	var vbuf = vertex_create_buffer_from_buffer(buf, vformat);
	vertex_freeze(vbuf);
	return vbuf;
}
