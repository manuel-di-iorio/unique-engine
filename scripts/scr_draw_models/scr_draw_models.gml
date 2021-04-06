function scr_draw_models(replaceColors) {
   	for (var i=0, l=stats.models; i<l; i++) {
		var model = models[i];
		
		// Check if the model has been selected
		if (selectedObj != model && selectedPxCol == model.selectionId && mouse_check_button_pressed(mb_left)) {
			selectedObj = model;
			alarm[1] = 1;
			scr_history_push(model);
			winMouse3DX_press = winMouse3DX;
			winMouse3DY_press = winMouse3DY;		
		}

		// When specified, set the selection shader color
		if (replaceColors) {
			shader_set(shdr_replace_color);
			shader_set_uniform_f(shdrReplaceCol_uCol, model.selectionR, model.selectionG, model.selectionB, 1);
		}

		// Draw the model's meshes
		scr_draw_model(model);
		
		if (selectedObj != -1) shader_reset();		
	}
}