function scr_draw_selectors(replaceColors) {
	var count = stats.selectors;
	
	for (var i=0; i<count; i++) {
		var selector = selectors[i];
		
		// Check if the model has been selected
		var selected = selectedPxCol == selector.selectionId && mouse_check_button_pressed(mb_left);
		if (selected) selectedObj = selector;
		
		var camDirX = point_direction(0, -o_ctrl.z, point_distance(o_ctrl.x, o_ctrl.y, selector.x, selector.y), -selector.z) ;
		var camDirZ = point_direction(o_ctrl.x, o_ctrl.y, selector.x, selector.y) - 90;
		var mat = matrix_build(selector.x, selector.y, selector.z, camDirX, selector.yrot, camDirZ, 1, 1, 1);
		matrix_set(matrix_world, mat);
		
		// When specified, set the selection shader color
		if (replaceColors) {
			shader_set(shdr_replace_color);
			shader_set_uniform_f(shdrReplaceCol_uCol, selector.selectionR, selector.selectionG, selector.selectionB);
		}
		
		vertex_submit(selector.vbuff, pr_trianglelist, selector.texture);
		
		if (selectedObj != -1) shader_reset();
	}
}