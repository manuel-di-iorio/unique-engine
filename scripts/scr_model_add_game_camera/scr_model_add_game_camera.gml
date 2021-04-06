function scr_model_add_game_camera() {
	var vbuff = scr_model_create_mesh(true);
	
	var x1 = -5;
	var z1 = -5;
	var x2 = 5;
	var z2 = 5;
	var col = c_white;
	var alpha = .8;
	
	// V component of UV are reversed
	// First triangle
	vertex_position_3d(vbuff, x2, 0, z2);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x1, 0, z1);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x2, 0, z1);
	vertex_texcoord(vbuff, 1, 1);
	vertex_color(vbuff, col, alpha);

    // Second triangle
	vertex_position_3d(vbuff, x2, 0, z2);
	vertex_texcoord(vbuff, 1, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x1, 0, z2);
	vertex_texcoord(vbuff, 0, 0);
	vertex_color(vbuff, col, alpha);

	vertex_position_3d(vbuff, x1, 0, z1);
	vertex_texcoord(vbuff, 0, 1);
	vertex_color(vbuff, col, alpha);
	scr_model_end_mesh(vbuff);
	
	var obj = {
		type: ObjectType.camera,
		vbuff: vbuff,
		x: -100 ,
		y: -100,
		z: 70,
		xrot: 0,
		yrot: 0,
		zrot: 0,
		xscale: 1,
		yscale: 1,
		zscale: 1,
		texture: sprite_get_texture(s_game_camera, 0)
	};
	scr_model_prebuild_matrix(obj);
	scr_obj_set_selection_id(obj);
	array_push(o_ctrl.selectors, obj);
	stats.selectors++;
	return obj;
}