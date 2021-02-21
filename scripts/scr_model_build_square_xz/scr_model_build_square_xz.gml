function scr_model_build_square_xz(vbuff, x1, y1, z1, x2, y2, z2, col, alpha) {
	vertex_position_3d(vbuff, x1, y1, z1);
	vertex_color(vbuff, col, alpha);
	vertex_position_3d(vbuff, x2, y1, z2);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x2, y1, z2);
	vertex_color(vbuff, col, alpha);
	vertex_position_3d(vbuff, x2, y2, z2);
	vertex_color(vbuff, col, alpha);
	
	vertex_position_3d(vbuff, x2, y2, z2);
	vertex_color(vbuff, col, alpha);
	vertex_position_3d(vbuff, x1, y2, z1);
	vertex_color(vbuff, col, alpha);
	
	vertex_position_3d(vbuff, x1, y2, z1);
	vertex_color(vbuff, col, alpha);
	vertex_position_3d(vbuff, x1, y1, z1);
	vertex_color(vbuff, col, alpha);
}