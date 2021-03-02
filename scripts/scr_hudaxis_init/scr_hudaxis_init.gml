function scr_hudaxis_init() {
	// Create the axis icon mesh
	scr_model_build_hud_axis();
	
	// Create the camera
	cameraHudAxis = camera_create();
	var projMat = matrix_build_projection_perspective_fov(-90, -cameraAspectRatio, 1, 300);
	camera_set_proj_mat(cameraHudAxis, projMat);
}