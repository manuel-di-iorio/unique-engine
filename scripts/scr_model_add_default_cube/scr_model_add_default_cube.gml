/**
 * Create a cube mesh
 */
function scr_model_add_default_cube(xpos, ypos) {
	var xx = -10;
	var yy = -10;
	var zz = -10;
	var size = 20;
	var col = c_white;
	var alpha = 1;
	
	var vbuff = scr_model_create_mesh(true, true);
	
	// Base
	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_normal(vbuff,0,0,1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,0,1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,0,1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,0,1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,0,1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_normal(vbuff,0,0,1);
	vertex_color(vbuff, col, alpha);

	// Front
	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_normal(vbuff,0,1,0);	
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,1,0);	
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_normal(vbuff,0,1,0);
	vertex_color(vbuff, col, alpha);

	// Back 
	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_normal(vbuff,0,-1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,-1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,-1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,-1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,-1,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_normal(vbuff,0,-1,0);
	vertex_color(vbuff, col, alpha);

	// Right
	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_normal(vbuff,1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_normal(vbuff,1,0,0);
	vertex_color(vbuff, col, alpha);

	// Left
	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_normal(vbuff,-1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,-1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,-1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx, yy, zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,-1,0,0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,-1,0,0);	
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy, zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_normal(vbuff,-1,0,0);
	vertex_color(vbuff, col, alpha);

	// Top
	vertex_position_3d(vbuff, xx, yy,size+zz);
	vertex_texcoord(vbuff, 0, 0);
	vertex_normal(vbuff,0,0,-1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,0,-1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,0,-1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 0, 1);
	vertex_normal(vbuff,0,0,-1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx, yy,size+zz);
	vertex_texcoord(vbuff, 1, 0);
	vertex_normal(vbuff,0,0,-1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff,size+xx,size+yy,size+zz);
	vertex_texcoord(vbuff, 1, 1);
	vertex_normal(vbuff,0,0,-1);
	vertex_color(vbuff, col, alpha);
	
	scr_model_end_mesh(vbuff);
	
	// Add the model to the models list
	o_ctrl.stats.models++;
	o_ctrl.stats.drawCalls++;
	
	var obj = {
		type: ObjectType.model,
		meshes: [{ vbuff: vbuff, sprite: -1, texture: tex_cube }],		
		meshesCount: 1,
		x: xpos,
		y: ypos,
		z: 10,
		xrot: 0,
		yrot: 0,
		zrot: 0,
		xscale: 1,
		yscale: 1,
		zscale: 1
	};
	scr_model_prebuild_matrix(obj);
	scr_obj_set_selection_id(obj);
	array_push(o_ctrl.models, obj);
}