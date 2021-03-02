function scr_hudaxis_update() {
	var xx, yy, zz, dx, dy, dz, matRotate, matTranslate, mat;
	if (!surface_exists(surfHudAxis)) surfHudAxis = surface_create(120, 120);
	
	/* Update the camera view mat */
	var xf = dcos(direction) * 80;
	var yf = dsin(direction) * 80;
	var zf = -dsin(zdir) * 80;
	
	camera_set_view_mat(cameraHudAxis, matrix_build_lookat(xf, yf, zf,  0, 0, 0, 0, 0, 1));
	
	/* Draw the axis mesh */
	surface_set_target(surfHudAxis);
	camera_apply(cameraHudAxis);
	gpu_set_fog(false, 0, 0, 0);
	gpu_set_zwriteenable(false);
	draw_clear_alpha(c_black, 0);
	vertex_submit(mesh_hud_axis_icon, pr_linelist, -1);
	
	/* Draw the axis characters */
	draw_set_halign(fa_center);	
	draw_set_valign(fa_middle);
	scale = .9;
	gpu_set_tex_filter(false);
	
	// X
	xx = 53; yy = 0; zz = 0;
	dx = point_direction(0, 0, xx, yy);
	dy = point_direction(0, 0, xx, yy);
	dz = point_direction(xx, yy, xf, yf);
	matRotate = matrix_build(0, 0, 0, 90 + dx, dy, 90 + dz, 1, 1, 1);	
	matTranslate = matrix_build(xx, yy, zz, 0, 0, 0, scale, scale, scale)
	mat = matrix_multiply(matRotate, matTranslate);
	matrix_set(matrix_world, mat);
	draw_set_color(c_white); draw_set_font(fHudAxisIcon);
	draw_text(0, 0, "X");
	
	// Y
	xx = 0; yy = 53; zz = 0;
	dx = point_direction(0, 0, xx, yy);
	dy = point_direction(0, 0, xx, yy);
	dz = point_direction(xx, yy, xf, yf);
	matRotate = matrix_build(0, 0, 0, 180 + dx, 90 + dy, 90 + dz, 1, 1, 1);	
	matTranslate = matrix_build(xx, yy, zz, 0, 0, 0, scale, scale, scale)
	mat = matrix_multiply(matRotate, matTranslate);
	matrix_set(matrix_world, mat);
	draw_set_color(c_white); draw_set_font(fHudAxisIcon);
	draw_text(0, 0, "Y");
	
	// Z
	xx = 0; yy = 0; zz = 53;
	dx = point_direction(0, 0, xx, yy);
	dy = point_direction(0, 0, xx, yy);
	dz = point_direction(xx, yy, xf, yf);
	matRotate = matrix_build(0, 0, 0, 180 + dx, dy, 90 + dz, 1, 1, 1);	
	matTranslate = matrix_build(xx, yy, zz, 0, 0, 0, 1.3, 1.3, 1.3)
	mat = matrix_multiply(matRotate, matTranslate);
	matrix_set(matrix_world, mat);
	draw_set_color(c_white); draw_set_font(fHudAxisIcon);
	draw_text(0, 0, "Z");
		
	surface_reset_target();
	scr_fog_enable();
	gpu_set_zwriteenable(true);
	matrix_set(matrix_world, matrix_build_identity());	
	gpu_set_tex_filter(settings.display.texfilter);
}