/**
 * Create a circle mesh
 */
function scr_model_build_circle(vbuff, xx, yy, zz, radius, col) {
	var steps = 6;
	var size = 1;
	
	for (var i=0; i<=360; i+=steps) {
		var xp = xx + lengthdir_x(radius, i);
		var yp = yy + lengthdir_y(radius, i);
		scr_model_build_plane(vbuff, xp-size, yp-size, 0, xp+size, yp+size, 0, col, 1);
		//vertex_position_3d(vbuff, xx + lengthdir_x(radius, i), yy + lengthdir_y(radius, i), 0);
		//vertex_color(vbuff, col, 1);
	}
}