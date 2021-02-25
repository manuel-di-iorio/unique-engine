function scr_model_build_grid() {
	gridVbuff = scr_model_create_mesh();
	
	var alpha;
	var dist = 32;
	var size = 100000;
	var count = ceil(size*2/dist);		

	for (var i=0; i<count; i++) {
		if (i % 10 == 0) { alpha = .8; } else { alpha = .4; }
		
		// Horizontal
		vertex_position_3d(gridVbuff, -size+i*dist, -size, 0);
		vertex_color(gridVbuff, c_gray, alpha);
		vertex_position_3d(gridVbuff, -size+i*dist, size, 0);
		vertex_color(gridVbuff, c_gray, alpha);
		
		// Vertical
		vertex_position_3d(gridVbuff, -size, -size+i*dist, 0);
		vertex_color(gridVbuff, c_gray, alpha);
		vertex_position_3d(gridVbuff, size, -size+i*dist, 0);
		vertex_color(gridVbuff, c_gray, alpha);
	}
	
	// Create the root center lines
	scr_model_build_line(gridVbuff, -size, 0, 0, size, 0, 0, Colors3D.x, 1);
	scr_model_build_line(gridVbuff, 0, -size, 0, 0, size, 0, Colors3D.y, 1);
	scr_model_build_line(gridVbuff, 0, 0, -size, 0, 0, size, Colors3D.z, 1);
	
	scr_model_end_mesh(gridVbuff);
}