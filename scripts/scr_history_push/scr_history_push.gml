/** 
 * Add the state of an object to the undo/redo system. List is capped at 100 items
 */
function scr_history_push(object) {
	var size = ds_list_size(history_list);
	
	// Check if the state has changed from the previous action
	if (history_index > 0) {
		var prevAction = history_list[| history_index-1].state;
		if (object.x == prevAction.x && object.y == prevAction.y && object.z == prevAction.z &&
		object.xrot == prevAction.xrot && object.yrot == prevAction.yrot && object.zrot == prevAction.zrot &&
		object.xscale == prevAction.xscale && object.yscale == prevAction.yscale && object.zscale == prevAction.zscale) return;
	}
	
	// Cap the list
	if (size > 99) {
		ds_list_delete(history_list, 0);
		size--;
	}
	
	// Replace the future
	size = ds_list_size(history_list);
	for (var i=history_index+1, l=size; i<l; i++) {
		ds_list_delete(history_list, history_index+1);
		size--;
	}
	
	// Push the state
	ds_list_add(history_list, { 
		object: object,
		state: {
			x: object.x,
			y: object.y,
			z: object.z,
			xrot: object.xrot,
			yrot: object.yrot,
			zrot: object.zrot,
			xscale: object.xscale,
			yscale: object.yscale,
			zscale: object.zscale,
		}
	});

	// Set the index to the latest perfomed action
	history_index = size;
}