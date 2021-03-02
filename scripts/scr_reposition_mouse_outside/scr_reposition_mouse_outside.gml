/**
 * When the mouse is outside the window border, move it on the other side, in order to allow unlimited movements
 */
function scr_reposition_mouse_outside_windows() {
	if (mouse_button == mb_none) return;
	var fixMousePos = false;
	
	if (winMouseX < 1) {
		window_mouse_set(winW-2, winMouseY);
		fixMousePos = true;
	} else if (winMouseY < 1) {
		window_mouse_set(winMouseX, winH-2);
		fixMousePos = true;
	} else if (winMouseX > winW-2) {
		window_mouse_set(1, winMouseY);
		fixMousePos = true;
	} else if (winMouseY > winH-2) {
		window_mouse_set(winMouseX, 2);
		fixMousePos = true;
	}
	
	if (fixMousePos) {
		winMouseX = window_mouse_get_x();
		winMouseY = window_mouse_get_y();
		winOldMouseX = winMouseX;
		winOldMouseY = winMouseY;
		scr_camera_get_mouse3d();
		winOldMouse3DX = winMouse3DX;
		winOldMouse3DY = winMouse3DY;
		winOldMouse3DZ = winMouse3DZ;
		winOldMouse3DY_planeX = winMouse3DY_planeX;
		winOldMouse3DZ_planeX = winMouse3DZ_planeX;
		winOldMouse3DX_planeY = winMouse3DX_planeY;
		winOldMouse3DZ_planeY = winMouse3DZ_planeY;
	}
}