/**
 * Create a cone mesh
 * @TODO: Face culling issue
 */
function scr_model_build_cone( vbuff, xx, yy, zz, length, radius, col, alpha) {
	var steps = 25;
	var theta = 0;
	//var phi = 0;
	var theta2 = 0;
	//var phi2 = 0;

	for (var i = 0; i < 2; i++) {
		for (var j = 0; j <= steps; j++) {
			theta = (j/steps)*2*pi;
			theta2 = ((j/steps)+1)*2*pi;
		
			// Sides
			if (i == 0) {		
				vertex_position_3d(vbuff,xx,yy,zz+length);
				//vertex_texcoord(vbuff,(t_ht/steps)*j,0);
				vertex_texcoord(vbuff, 0, 0); // @todo
				vertex_normal(vbuff,0,0,-1);
				vertex_color(vbuff, col, alpha);			
	
				vertex_position_3d(vbuff,xx+radius*cos(theta),yy+radius*sin(theta),zz);
				//vertex_texcoord(vbuff,(t_ht/steps)*j,t_vt);
				vertex_texcoord(vbuff, 0, 0); // @todo
				vertex_normal(vbuff,cos(theta),sin(theta),0);
				vertex_color(vbuff, col, alpha);			
					
				vertex_position_3d(vbuff,xx+radius*cos(theta2),yy+radius*sin(theta2),zz);
				//vertex_texcoord(vbuff,(t_ht/steps)*j,t_vt);	
				vertex_texcoord(vbuff, 0, 0); // @todo
				vertex_normal(vbuff,cos(theta2),sin(theta2),0);
				vertex_color(vbuff, col, alpha);
			}
		
			//Base
			/*else if (i == 1) {
				vertex_position_3d(vbuff,xx,yy,zz);
				//vertex_texcoord(vbuff,0.5*t_hu,0.5*t_vu);	
				vertex_texcoord(vbuff, 0, 0); // @todo
				vertex_normal(vbuff,0,0,1);
				vertex_color(vbuff, c_orange, 1);			
	
				vertex_position_3d(vbuff,xx+size*cos(theta),yy+size*sin(theta),zz);
				//vertex_texcoord(vbuff,(0.5+(cos(theta)/2))*t_hu,(0.5+(sin(theta)/2))*t_vu);	
				vertex_texcoord(vbuff, 0, 0); // @todo
				vertex_normal(vbuff,cos(theta),sin(theta),1);
				vertex_color(vbuff, c_orange, 1);			
	
				vertex_position_3d(vbuff,xx+size*cos(theta2),yy+size*sin(theta2),zz);
				//vertex_texcoord(vbuff,(0.5+(cos(theta2)/2))*t_hu,(0.5+(sin(theta2)/2))*t_vu);
				vertex_texcoord(vbuff, 0, 0); // @todo
				vertex_normal(vbuff,cos(theta2),sin(theta2),1);
				vertex_color(vbuff, c_orange, 1);			
			}*/
		}
	}
}