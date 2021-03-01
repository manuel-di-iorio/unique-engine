/**
 * Get the mouse 3D position from the XY screen-space position
 */
function scr_camera_get_mouse3d() {
	var _x = winMouseX;
	var _y = winH - winMouseY;
	var V = camViewMat;
	var P = camProjMat;

	var mx = 2 * (_x / winW - .5) / P[0];
	var my = 2 * (_y / winH - .5) / P[5];
	var camX = - (V[12] * V[0] + V[13] * V[1] + V[14] * V[2]);
	var camY = - (V[12] * V[4] + V[13] * V[5] + V[14] * V[6]);
	var camZ = - (V[12] * V[8] + V[13] * V[9] + V[14] * V[10]);

	var dx = V[2]  + mx * V[0] + my * V[1];
	var dy = V[6]  + mx * V[4] + my * V[5];
	var dz = V[10] + mx * V[8] + my * V[9];
				
	var zSign = sign(z);
	winMouse3DX = x + dx*z * zSign;
	winMouse3DY = y + dy*z * zSign;
	winMouse3DZ = z + dz*z * zSign;
}