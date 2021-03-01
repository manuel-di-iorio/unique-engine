function scr_setup_3d() {
	gpu_set_zwriteenable(true);
	gpu_set_ztestenable(true);
	gpu_set_texrepeat(true);
	gpu_set_alphatestenable(true);
	//gpu_set_cullmode(cull_counterclockwise); // @todo: some models are not correctly culled
	gpu_set_texfilter(true);
	gpu_set_tex_mip_enable(true);		
	view_enabled = true;
	view_set_visible(0, true);	
	camera = camera_create();
	
	// Fog
	fogcolor = $252525;
	fogstart = 100;
	fogend = 15000;
	scr_fog_enable();
	
	// Lightning
	scr_lightning_enable();
	draw_light_define_ambient($202020);
	draw_light_define_point(0, -70, 70, 0, 1000, $D6F4FF);
	draw_light_enable(0, true);
	
	var projMat = matrix_build_projection_perspective_fov(-cameraFov, -cameraAspectRatio, 1, 32000);
	camera_set_proj_mat(camera, projMat);
	view_set_camera(0, camera);
	camera_set_update_script(camera, scr_update_camera_mat);	
}