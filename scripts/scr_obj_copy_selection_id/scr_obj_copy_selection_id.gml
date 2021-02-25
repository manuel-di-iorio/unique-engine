/**
 * Get the incremented pixel-surface selection ID, from another object
  */
function scr_obj_copy_selection_id(objSource, objDest) {
	objDest.selectionId = objSource.selectionId;
	objDest.selectionR = objSource.selectionR;
	objDest.selectionG = objSource.selectionG;
	objDest.selectionB = objSource.selectionB;
}