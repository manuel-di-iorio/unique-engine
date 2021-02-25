/**
 * Get the incremented pixel-surface selection ID
  */
function scr_obj_set_selection_id(obj) {
	var col = o_ctrl.selectionId++;
	obj.selectionId = col;
	obj.selectionR = color_get_red(col) * .0039;
	obj.selectionG = color_get_green(col) * .0039;
	obj.selectionB = color_get_blue(col) * .0039;
}