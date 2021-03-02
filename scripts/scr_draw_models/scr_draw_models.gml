function scr_draw_models(replaceColors) {
   	for (var i=0, l=stats.models; i<l; i++) {
		var model = models[i];
		
		// Check if the model has been selected
		var selected = selectedObj != model && selectedPxCol == model.selectionId && mouse_check_button_pressed(mb_left);
		if (selected) {
			selectedObj = model;
			alarm[1] = 1;
			scr_history_push(model);
			winMouse3DX_press = winMouse3DX;
			winMouse3DY_press = winMouse3DY;		
		}

		// Transform the model
		var mat = matrix_build(
			model.x, model.y, model.z, 
			model.xrot, model.yrot, model.zrot,
			model.xscale, model.yscale, model.zscale
		);
		matrix_set(matrix_world, mat);
		
		// When specified, set the selection shader color
		if (replaceColors) {
			shader_set(shdr_replace_color);
			shader_set_uniform_f(shdrReplaceCol_uCol, model.selectionR, model.selectionG, model.selectionB);
		}
		
		// Draw the model's meshes
		var meshes = model.meshes;		
		for (var j=0, k=model.meshesCount; j<k; j++) {
			var mesh = meshes[j];
			vertex_submit(mesh.vbuff, pr_trianglelist, mesh.texture);
		}
		
		if (selectedObj != -1) shader_reset();		
	}
}