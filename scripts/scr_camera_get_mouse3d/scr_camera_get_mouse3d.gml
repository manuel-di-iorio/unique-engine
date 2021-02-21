/**
 * Get the mouse 3D position from the XY screen-space position
 */
 // @todo: not working properly
function scr_camera_get_mouse3d() {
	var abs_zdir = abs(abs(zdir)-90);
	var zdir2 = 90 - abs_zdir;

	var xto = x + (dcos(direction) * dcos(-zdir)) * abs(z) / dsin(zdir2);  
	var yto = y + (dsin(direction) * -dcos(-zdir)) * abs(z) / dsin(zdir2); 

	var mdir = point_direction(winW/2, winH/2, winMouseX, winMouseY); 
	var mdis = point_distance(winW/2, winH/2, winMouseX, winMouseY);
	var deg = direction - 90 + mdir;

	winMouse3DX = -(xto + lengthdir_x(mdis * (-z/(winW/(2+abs_zdir)*2)), deg));
	winMouse3DY = -(yto + lengthdir_y(mdis * (-z/(winW/(2+abs_zdir)*2)), deg));
}