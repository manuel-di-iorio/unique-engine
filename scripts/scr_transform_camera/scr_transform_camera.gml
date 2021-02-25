/**
 * Handle the camera transform on user input (mouse/keyword)
 */
function scr_transform_camera() {
	var dx = camViewMat[2];
	var dy = camViewMat[6];
	var dz = camViewMat[10];
	var cameraSpeed = 2;
	var shiftSpd = keyboard_check(vk_shift) * 4;
	
	// Lateral movement
	if (keyboard_check(ord("A"))) {
		  x = x - dsin(direction) * (cameraSpeed+shiftSpd);
		  y = y - dcos(direction) * (cameraSpeed+shiftSpd);
	} else if (keyboard_check(ord("D"))) {
		  x = x  + dsin(direction) * (cameraSpeed+shiftSpd);
		  y = y  + dcos(direction) * (cameraSpeed+shiftSpd);
	}
	
	// Forward/backward movement
	if (keyboard_check(ord("S"))) {
		speed = -(cameraSpeed+shiftSpd);
	} else if (keyboard_check(ord("W"))) {
		speed = (cameraSpeed+shiftSpd);
	} else {
		speed = 0; 
	}
	
	// Rotate camera 
	if(mouse_check_button(mb_right)) {
		window_set_cursor(cr_none);
		cursorSprite = s_cursor_eye;
		direction -= (winMouseX - winOldMouseX) / 10;
		zdir += (winMouseY - winOldMouseY) / 10;
			
		if (zdir < -89) {
			zdir = -89;
		} else if (zdir > 89) {
			zdir = 89;
		}
	}
	
	// Elevate/descend
	if (keyboard_check(ord("E"))) {
		z += 1;	
	}
	if (keyboard_check(ord("Q"))) {
		z -= 1;
	}
	
	// Move the camera towards the direction its facing
	if (mouse_wheel_up()) {
		x += dx*cameraSpeed*2;
		y += dy*cameraSpeed*2;
		z += dz*cameraSpeed*2;
	}
	
	if (mouse_wheel_down()) {
		x -= dx*cameraSpeed*2;
		y -= dy*cameraSpeed*2;
		z -= dz*cameraSpeed*2;
	}
	
	// Camera Pan
	if (mouse_check_button(mb_middle)) {
		window_set_cursor(cr_none);
		cursorSprite = s_cursor_drag;
		
		// XY Pan
		if (winMouseX > winOldMouseX) {
			shfDir = -90;
		} else if (winMouseX < winOldMouseX) {
			shfDir = 90;
		} else { 
			shfDir = 0;
		}
		var delta = abs(winMouseX - winOldMouseX)/5;
		if (shfDir != 0) {
			x += dcos(direction+shfDir) * dcos(-zdir) * delta;
			y +=  dsin(direction+shfDir) * -dcos(-zdir) * delta;
		}
		
		// Z Pan
		if (winMouseY > winOldMouseY) {
			shfDir = -90;
		} else if (winMouseY < winOldMouseY) {
			shfDir = 90;
		} else { 
			shfDir = 0;
		}
		var delta = abs(winMouseY - winOldMouseY)/5;
		if (shfDir != 0) {
			z -= -dsin(o_ctrl.zdir+shfDir) * delta;
		}
	}
	
	// Update the selection surface when the scene has finished changing
	if (keyboard_check_released(ord("A")) || keyboard_check_released(ord("D")) || 
	keyboard_check_released(ord("W")) ||keyboard_check_released(ord("S")) || 
	keyboard_check_released(ord("E")) || mouse_check_button_released(mb_right) ||
	keyboard_check_released(ord("Q")) || mouse_check_button_released(mb_middle) ||
	mouse_wheel_up() || mouse_wheel_down()) {
		scr_update_pxsurface();
		window_set_cursor(cr_default);
		cursorSprite = -1;
	}
}