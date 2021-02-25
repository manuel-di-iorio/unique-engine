/**
 * Add a selector mesh to the list
 */
function scr_model_add_selector(x, y, z, yrot, texture) {
	var vbuff = scr_model_create_mesh(true);
	scr_model_build_plane(vbuff, -8, 0, -8, 8, 0, 8, c_white, .8);
	scr_model_end_mesh(vbuff);
	
	var object = { x: x, y: y, z: z, yrot: yrot, vbuff: vbuff, texture: texture  };
	scr_obj_set_selection_id(object);
	stats.selectors++;
	array_push(selectors, object);
}