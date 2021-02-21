// @todo
function scr_model_build_cylinder(vbuff, x1, y1, z1, x2, y2, z2, size) {
	var steps = 10;

	var theta = 0;
	var phi = 0;
	var theta2 = 0;
	var phi2 = 0;

	for(i = 0; i <= 2; i++) 
	{
		for(j = 0; j <= steps; j++) 
		{
			theta = (j/steps)*2*pi;
			theta2 = ((j/steps)+1)*2*pi;

			//Top
			if(i == 0)
			{
				vertex_position_3d(vbuff,xx,yy,zz-size);
				//vertex_texcoord(vbuff,0.5*t_ht,0.5*t_vt); // @todo
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,0,0,-1);
				vertex_color(vbuff, c_white, 1);
	
				vertex_position_3d(vbuff,xx+size*cos(theta),yy+size*sin(theta),zz-size);
				//vertex_texcoord(vbuff,(0.5+(cos(theta)/2))*t_ht,(0.5+(sin(theta)/2))*t_vt);	
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,0,0,-1);
				vertex_color(vbuff, c_white, 1);
	
				vertex_position_3d(vbuff,xx+size*cos(theta2),yy+size*sin(theta2),zz-size);
				//vertex_texcoord(vbuff,(0.5+(cos(theta2)/2))*t_ht,(0.5+(sin(theta2)/2))*t_vt);
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,0,0,-1);
				vertex_color(vbuff, c_white, 1);
			}
		
			//Sides
			if(i == 1)
			{		
				vertex_position_3d(vbuff,xx+size*cos(theta),yy+size*sin(theta),zz-size);
				//vertex_texcoord(vbuff,(t_hf/steps)*j,0);	
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,cos(theta),sin(theta),0);
				vertex_color(vbuff, c_white, 1);
				
				vertex_position_3d(vbuff,xx+size*cos(theta),yy+size*sin(theta),zz);
				//vertex_texcoord(vbuff,(t_hf/steps)*j,t_vf);
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,cos(theta),sin(theta),0);
				vertex_color(vbuff, c_white, 1);			
					
				vertex_position_3d(vbuff,xx+size*cos(theta2),yy+size*sin(theta2),zz-size);
				//vertex_texcoord(vbuff,(t_hf/steps)*j,0);	
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,cos(theta2),sin(theta2),0);
				vertex_color(vbuff, c_white, 1);			

				vertex_position_3d(vbuff,xx+size*cos(theta2),yy+size*sin(theta2),zz);
				//vertex_texcoord(vbuff,(t_hf/steps)*j,t_vf);
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,cos(theta2),sin(theta2),0);
				vertex_color(vbuff, c_white, 1);			
			}
		
			//Base
			if(i == 2)
			{
				vertex_position_3d(vbuff,xx,yy,zz);
				//vertex_texcoord(vbuff,0.5*t_hu,0.5*t_vu);
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,0,0,1);
				vertex_color(vbuff, c_white, 1);			
	
				vertex_position_3d(vbuff,xx+size*cos(theta),yy+size*sin(theta),zz);
				//vertex_texcoord(vbuff,(0.5+(cos(theta)/2))*t_hu,(0.5+(sin(theta)/2))*t_vu);	
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,0,0,1);
				vertex_color(vbuff, c_white, 1);			
	
				vertex_position_3d(vbuff,xx+size*cos(theta2),yy+size*sin(theta2),zz);
				//vertex_texcoord(vbuff,(0.5+(cos(theta2)/2))*t_hu,(0.5+(sin(theta2)/2))*t_vu);
				vertex_texcoord(vbuff, 0, 0);	
				vertex_normal(vbuff,0,0,1);
				vertex_color(vbuff, c_white, 1);
			}
		}
	}
}