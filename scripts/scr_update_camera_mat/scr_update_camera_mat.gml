/** 
 * Update the view matrix of the camera
 */
function scr_update_camera_mat() {		
	var cameraXT = o_ctrl.x + dcos(o_ctrl.direction) * dcos(-o_ctrl.zdir);
	var cameraYT = o_ctrl.y + dsin(o_ctrl.direction) * -dcos(-o_ctrl.zdir);
	var cameraZT = o_ctrl.z - dsin(o_ctrl.zdir);
	
	camera_set_view_mat(view_camera, matrix_build_lookat(
		o_ctrl.x, o_ctrl.y, o_ctrl.z,  // From
		cameraXT, cameraYT, cameraZT, // To
		0, 0, 1 // Up
	));
}