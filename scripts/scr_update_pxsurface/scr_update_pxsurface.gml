/**
 * Draw the scene on the Pixel Surface
 */
function scr_update_pxsurface() {
	if (!surface_exists(pxSurface)) pxSurface = surface_create(winW, winH);

	if (settings.display.aa != 0) display_reset(0, settings.display.vsync);
	gpu_set_fog(false, 0, 0, 0);
	surface_set_target(pxSurface);
	camera_apply(camera);
	draw_clear_alpha(c_black, 0);  
	scr_draw_scene(true);
	surface_reset_target();
	camera_apply(camera);
	scr_fog_enable();	
	scr_enable_aa();	
	
  	// Copy the content of the surface into the buffer
	buffer_get_surface(pxBuffer, pxSurface, 0);
}