function scr_model_build_plane_xz(vbuff, x1, y1, z1, x2, y2, z2, col, alpha) {
	// First triangle
	vertex_position_3d(vbuff, x2, y2, z2);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x1, y1, z1);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x1, y2, z1);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

    // Second triangle
	vertex_position_3d(vbuff, x2, y2, z2);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x2, y1, z2);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x1, y1, z1);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);
}