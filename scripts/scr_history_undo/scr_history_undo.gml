/** 
 * Revert to the previous performed action in the history
 */
function scr_history_undo() {
	if (!history_index) return;
	var currentAction = history_list[| history_index];	
	history_index--;
	var newAction = history_list[| history_index];
	
	// If the undo action affects a different object, go back of another action, otherwise nothing will be changed
	if (history_index > 0 && currentAction.object.selectionId != newAction.object.selectionId) {
		history_index--;
		newAction = history_list[| history_index];
	}
	
	scr_history_set_state(newAction);
}