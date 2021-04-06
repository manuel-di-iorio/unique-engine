/**
 * Script called when an object has been changed
 */
function scr_on_object_change(obj) {
	// Cache the object transform matrix
	scr_model_prebuild_matrix(obj);
	
	// Update the window caption
	var winCaption = window_get_caption();
	if (!string_last_pos("*", winCaption)) window_set_caption(winCaption + "*");
	
	// Push the object change
	array_push(projectChanges, {
		type: ProjectChangeType.objectTransformed,
		object: obj
	});
}