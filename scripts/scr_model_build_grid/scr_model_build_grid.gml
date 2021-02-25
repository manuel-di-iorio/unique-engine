function scr_model_build_grid() {
	if (gridVbuff != -1) {
		// Rebuild the grid
		vertex_delete_buffer(gridVbuff);
	}
	
	gridVbuff = scr_model_create_mesh();
	
	var alpha;
	var size = 100000;
	
	var xdist = settings.grid.xoffset;
	var xcount = ceil(size*2/xdist);
	
	var ydist = settings.grid.yoffset;
	var ycount = ceil(size*2/ydist);	

	for (var i=0; i<xcount; i++) {
		if (i % 10 == 0) { alpha = .8; } else { alpha = .4; }
		
		// Horizontal
		vertex_position_3d(gridVbuff, -size+i*xdist, -size, 0);
		vertex_color(gridVbuff, c_gray, alpha);
		vertex_position_3d(gridVbuff, -size+i*xdist, size, 0);
		vertex_color(gridVbuff, c_gray, alpha);
	}
	
	for (var i=0; i<ycount; i++) {
		if (i % 10 == 0) { alpha = .8; } else { alpha = .4; }
		
		// Vertical
		vertex_position_3d(gridVbuff, -size, -size+i*ydist, 0);
		vertex_color(gridVbuff, c_gray, alpha);
		vertex_position_3d(gridVbuff, size, -size+i*ydist, 0);
		vertex_color(gridVbuff, c_gray, alpha);
	}
	
	// Create the root center lines
	scr_model_build_line(gridVbuff, -size, 0, 0, size, 0, 0, Colors3D.x, 1);
	scr_model_build_line(gridVbuff, 0, -size, 0, 0, size, 0, Colors3D.y, 1);
	scr_model_build_line(gridVbuff, 0, 0, -size, 0, 0, size, Colors3D.z, 1);
	
	scr_model_end_mesh(gridVbuff);
}