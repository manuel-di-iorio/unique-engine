/**
 * Create a cone mesh
 * @TODO: Face culling issue
 */
function scr_model_build_cone( vbuff, xx, yy, zz, length, radius, col, alpha) {
	var steps = 25;
	var theta = 0;
	var theta2 = 0;

	for (var j = 0; j <= steps; j++) {
		theta = (j/steps)*2*pi;
		theta2 = ((j/steps)+1)*2*pi;
		
		vertex_position_3d(vbuff,xx,yy,zz+length);
		vertex_texcoord(vbuff,(1/steps)*j,0);
		vertex_normal(vbuff,0,0,-1);
		vertex_color(vbuff, col, alpha);			
	
		vertex_position_3d(vbuff,xx+radius*cos(theta),yy+radius*sin(theta),zz);
		vertex_texcoord(vbuff,(1/steps)*j,1);
		vertex_normal(vbuff,cos(theta),sin(theta),0);
		vertex_color(vbuff, col, alpha);			
					
		vertex_position_3d(vbuff,xx+radius*cos(theta2),yy+radius*sin(theta2),zz);
		vertex_texcoord(vbuff,(1/steps)*j,1);	
		vertex_normal(vbuff,cos(theta2),sin(theta2),0);
		vertex_color(vbuff, col, alpha);
	}
}