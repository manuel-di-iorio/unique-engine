/**
 * Get the mouse 3D position from the XY screen-space position
 * @author flyingsaucerinvasion
 * @updated by: Xeryan
 */
function scr_camera_get_mouse3d() {
	var _t;
	var _x = cameraAspectRatio * dtan(cameraFov /2) * (2 * winMouseX / winW - 1);
	var _y = dtan(cameraFov /2) * (1 - 2 * winMouseY / winH);
	mouse_vector_x = _x * camViewMat[0] + _y * camViewMat[1] + camViewMat[2];
	mouse_vector_y = _x * camViewMat[4] + _y * camViewMat[5] + camViewMat[6];
	mouse_vector_z = _x * camViewMat[8] + _y * camViewMat[9] + camViewMat[10];

	// Project to plane X
	if (mouse_vector_x != 0) {  // mouse vector isn't parallel to floor
	   _t = -x / mouse_vector_x;
	    winMouse3DY_planeX = x + mouse_vector_y * _t * sign(_t);
		winMouse3DZ_planeX = z + mouse_vector_z * _t * sign(_t);
	}
	
	// Project to plane Y
	if (mouse_vector_y != 0) {  // mouse vector isn't parallel to floor
	   _t = -y / mouse_vector_y;
	    winMouse3DX_planeY = x + mouse_vector_x * _t;
		winMouse3DZ_planeY = z + mouse_vector_z * _t;
	}
	
	// Project to plane Z
	if (mouse_vector_z != 0) {  //mouse vector isn't parallel to floor
	   _t = -z / mouse_vector_z;
	    winMouse3DX = x + mouse_vector_x * _t;
	    winMouse3DY = y + mouse_vector_y * _t;
	}
}