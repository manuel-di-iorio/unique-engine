function scr_reposition_mouse_outside_windows() {
	if (mouse_button != mb_middle && mouse_button != mb_right) return;
	var fixMousePos = false;
	
	if (winMouseX < 1) {
		window_mouse_set(winW-2, winMouseY);
		fixMousePos = true;
	} else if (winMouseY < 5) {
		window_mouse_set(winMouseX, winH-5);
		fixMousePos = true;
	} else if (winMouseX > winW-2) {
		window_mouse_set(1, winMouseY);
		fixMousePos = true;
	} else if (winMouseY > winH-5) {
		window_mouse_set(winMouseX, 5);
		fixMousePos = true;
	}
	
	if (fixMousePos) {
		winMouseX = window_mouse_get_x();
		winMouseY = window_mouse_get_y();
		winOldMouseX = winMouseX;
		winOldMouseY = winMouseY;
	}
}