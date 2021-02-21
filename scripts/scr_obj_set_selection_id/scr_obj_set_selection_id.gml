/**
 * Get the incremented pixel-surface selection ID
  */
function scr_obj_set_selection_id(obj) {
	var col = o_ctrl.selectionId++;
	obj.selectionId = col;
	obj.selectionR = color_get_red(col);
	obj.selectionG = color_get_green(col);
	obj.selectionB = color_get_blue(col);
}