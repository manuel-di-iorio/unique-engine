function scr_draw_models(replaceColors) {
	var modelsCount = stats.models;
	
   	for (var i=0; i<modelsCount; i++) {
		var model = models[i];
		
		// Check if the model has been selected
		var selected = selectedPxCol == model.selectionId && mouse_check_button_pressed(mb_left);
		if (selected) selectedObj = model;

		// Transform the model
		var  mat = matrix_build(
			model.x, model.y, model.z, 
			model.xrot, model.yrot, model.zrot,
			model.xscale, model.yscale, model.zscale
		);
		matrix_set(matrix_world, mat);
		
		// When specified, set the selection shader color
		if (replaceColors) {
			shader_set(shdr_replace_color);
			shader_set_uniform_f(shdrReplaceCol_uCol, model.selectionR*.0039, model.selectionG*.0039, model.selectionB*.0039);
		} else if (selectedObj == model) {
			// If the model is selected, blend the color via shader
			//shader_set(shdr_blend_color);
			//shader_set_uniform_f(shdrBlendCol_uCol, 102*.0039, 204*.0039, 255*.0039);
		}
		
		// Draw the model's meshes
		var meshes = model.meshes;		
		var meshesCount = model.meshesCount;
		for (var j=0; j<meshesCount; j++) {
			var mesh = meshes[i];
			vertex_submit(mesh.vbuff, pr_trianglelist, mesh.texture);
		}
		
		if (selectedObj != -1) shader_reset();		
	}
}