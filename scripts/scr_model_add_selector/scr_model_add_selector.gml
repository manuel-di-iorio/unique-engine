/**
 * Add a selector mesh to the list
 */
function scr_model_add_selector(x, y, z, yrot, texture) {
	var vbuff = scr_model_create_mesh(true);
	scr_model_build_plane(vbuff, -5, 0, -5, 5, 0, 5, c_white, .8);
	scr_model_end_mesh(vbuff);
	
	var object = { type: ObjectType.selector, x: x, y: y, z: z, xrot: 0, yrot: yrot, zrot: 0, xscale: 1, yscale: 1, zscale: 1, vbuff: vbuff, texture: texture  };
	scr_obj_set_selection_id(object);
	stats.selectors++;
	array_push(selectors, object);
}