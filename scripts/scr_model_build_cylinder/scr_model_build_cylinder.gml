function scr_model_build_cylinder(xx, yy, zz, radius, height, col, alpha) {
	var vbuff = scr_model_create_mesh(true);
	
	var steps = 24;
	var theta = 0;
	var phi = 0;
	var theta2 = 0;
	var phi2 = 0;
	var halfHeight = height/2;
	
	for(var j = 0; j <= steps; j++) {
		theta = (j/steps)*2*pi;
		theta2 = ((j/steps)+1)*2*pi;
			
		vertex_position_3d(vbuff,xx+radius*cos(theta), yy+radius*sin(theta), zz-halfHeight);
		vertex_texcoord(vbuff,(1/steps)*j, 0);	
		vertex_color(vbuff, col, alpha);
				
		vertex_position_3d(vbuff,xx+radius*cos(theta), yy+radius*sin(theta), zz+halfHeight);
		vertex_texcoord(vbuff,(1/steps)*j, 1);
		vertex_color(vbuff, col, alpha);			
					
		vertex_position_3d(vbuff,xx+radius*cos(theta2), yy+radius*sin(theta2), zz-halfHeight);
		vertex_texcoord(vbuff,(1/steps)*j, 0);	
		vertex_color(vbuff, col, alpha);			

		vertex_position_3d(vbuff,xx+radius*cos(theta2), yy+radius*sin(theta2), zz+halfHeight);
		vertex_texcoord(vbuff,(1/steps)*j, 1);
		vertex_color(vbuff, col, alpha);			
	}
	
	scr_model_end_mesh(vbuff);
	return vbuff;
}