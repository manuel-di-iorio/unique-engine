/**
 * Draw the scene
 */
function scr_draw_scene(replaceColors) {
	// Draw the models
	scr_draw_models(replaceColors);
	
	gpu_set_ztestenable(false);
	
	 // Draw the selectors 
	 if (!drawGameOnly) {
		scr_draw_selectors(replaceColors);
	
		// Draw the mesh gizmo
		scr_draw_gizmo(replaceColors);
	 }
	
	gpu_set_ztestenable(true);
	
	// Reset the draw changes
	matrix_set(matrix_world, matrix_build_identity());
	
	if (replaceColors) shader_reset();
}