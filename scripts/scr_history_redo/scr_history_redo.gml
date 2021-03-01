/** 
 * Revert to the next performed action in the history current position
 */
function scr_history_redo() {
	var size = ds_list_size(history_list);
	if (size < 2 || history_index == size-1) return;
	var currentAction = history_list[| history_index];
	history_index++;
	var newAction = history_list[| history_index];
	
	// If the redo action affects a different object, go forward of another action, otherwise nothing will be changed
	if (history_index < size-1 && currentAction.object.selectionId != newAction.object.selectionId) {
		history_index++;
		newAction = history_list[| history_index];
	}
	
	scr_history_set_state(newAction);
}