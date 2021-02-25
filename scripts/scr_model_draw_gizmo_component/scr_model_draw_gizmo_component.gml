/**
 * Draw a gizmo component and handle the input
 */
function scr_model_draw_gizmo_component(replaceColors, component, xx, yy, zz, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, hiddenScaleFactor) {
	var selectionId = component.selectionId;
	
	// Check if the component has been selected
	var is_hovering = false;
	if (selectedGizmo.selectionId == selectionId && mouse_check_button_released(mb_left)) {
		selectedGizmo = -1;
		scr_update_pxsurface();
	} else if (selectedPxCol == selectionId) {
		is_hovering = true;
		if (mouse_check_button_pressed(mb_left)) {
			selectedGizmo = component;
		}
	}
	
	matrix_stack_push(matrix_build(xx, yy, zz, rotX, rotY, rotZ, scaleX, scaleY, scaleZ));
	if (replaceColors && hiddenScaleFactor) matrix_stack_push(matrix_build(0, 0, 0, 0, 0, 0, hiddenScaleFactor, hiddenScaleFactor/3, 1));
	matrix_set(matrix_world, matrix_stack_top());
	matrix_stack_clear();
	
	if (replaceColors) {
		// Replace the color for the selection surface		
		shader_set(shdr_replace_color);
		shader_set_uniform_f(shdrReplaceCol_uCol, component.selectionR, component.selectionG, component.selectionB);
	} else if (selectedGizmo.selectionId == selectionId) {
		shader_set(shdr_replace_color);
		shader_set_uniform_f(shdrReplaceCol_uCol, ColorSelectionR, ColorSelectionG, ColorSelectionB);
	} else if (selectedGizmo == -1 && is_hovering) {
		shader_set(shdr_blend_color);
		shader_set_uniform_f(shdrBlendCol_uCol, ColorHoverR, ColorHoverG, ColorHoverB);
	} 
	
	vertex_submit(component.vbuff, component.prim, -1);
	shader_reset();
}