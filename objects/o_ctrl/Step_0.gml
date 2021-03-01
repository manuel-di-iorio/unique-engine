 camViewMat = camera_get_view_mat(view_camera);
 camProjMat = camera_get_proj_mat(view_camera);

// Move the mouse on the other edge of the screen, when transforming the camera with the mouse
scr_reposition_mouse_outside_windows();

winMouseX = window_mouse_get_x();
winMouseY = window_mouse_get_y();
winW = window_get_width();
winH = window_get_height();

// Detect the window resize event
if (winW != 0 && winH != 0 && (winW != winOldW || winH != winOldH)) {
	scr_on_window_resize();
}

// Get the mouse 3D position
scr_camera_get_mouse3d();

// Transform the obs based on the gizmos input
scr_transform_objs();

// Handle the camera transform on user input
scr_transform_camera();

// Get the pixel color on mouse click
if (mouse_check_button_pressed(mb_left)) scr_update_pxsurface();
scr_getpixel_pxsurface(winMouseX, winMouseY);

// Delesect the current selected object
if (selectedObj != -1 && selectedGizmo == -1 && selectedPxCol == 0 && mouse_check_button_released(mb_left) ) {
	selectedObj = -1;	
}

// History
if (keyboard_check(vk_control)) {
	if (keyboard_check_pressed(ord("Z"))) {
		scr_history_undo();
	} else if (keyboard_check_pressed(ord("Y"))) {
		scr_history_redo();
	}
}