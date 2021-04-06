// Update the selection outline surface
function scr_selection_outline_surf_update() {
	if (!surface_exists(surfSelectionOutline)) surfSelectionOutline = surface_create(winW, winH);
	if (selectedObj == -1 || selectedObj.type != ObjectType.model) return;
	
	gpu_set_ztestenable(false);
	surface_set_target(surfSelectionOutline);
	camera_apply(view_camera);
	draw_clear_alpha(c_black, 0);
	
	// Draw the scaled object with the colors fully replaced	
	shader_set(shdr_replace_color);
	shader_set_uniform_f(shdrReplaceCol_uCol, ColorHoverR, ColorHoverG, ColorHoverB, 1);
	var scale = .015;
	selectedObj.xscale += scale; selectedObj.yscale += scale; selectedObj.zscale += scale; 
	scr_draw_model(selectedObj);
	selectedObj.xscale -= scale; selectedObj.yscale -= scale; selectedObj.zscale -= scale; 
	
	// Draw the unscaled model subtracting the pixels
	shader_reset();
	gpu_set_blendmode(bm_subtract);
	scr_draw_model(selectedObj);
	
	matrix_set(matrix_world, matrix_build_identity());
	shader_reset();
	surface_reset_target();		
	gpu_set_blendmode(bm_normal);
	gpu_set_ztestenable(true);
}