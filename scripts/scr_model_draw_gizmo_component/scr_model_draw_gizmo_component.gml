/**
 * Draw a gizmo component and handle the input
 */
function scr_model_draw_gizmo_component(replaceColors, component, xx, yy, zz, rotX, rotY, rotZ, scaleX, scaleY, scaleZ) {
	// Check if the component has been selected
	var is_hovering = false;
	if (selectedGizmo == component && mouse_check_button_released(mb_left)) {
		selectedGizmo = -1;
	} else if (selectedPxCol == component.selectionId) {
		is_hovering = true;
		if (mouse_check_button_pressed(mb_left)) selectedGizmo = component;
	}
	
	var mesh;
	if (replaceColors) {
		// Replace the color for the selection surface
		mesh = component.meshReplace;
	} else if (selectedGizmo) {
		mesh = component.meshSelected;
	} else if (is_hovering) {
		mesh = component.meshHover;
	} else {
		 mesh = component.mesh;
	}	
	
	var mat = matrix_build(xx, yy, zz, rotX, rotY, rotZ, scaleX, scaleY, scaleZ);
	matrix_set(matrix_world, mat);
	vertex_submit(mesh, component.prim, -1);
}