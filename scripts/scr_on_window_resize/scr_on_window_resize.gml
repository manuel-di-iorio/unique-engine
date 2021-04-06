function scr_on_window_resize() {
	winW = window_get_width();
	winH = window_get_height();
	
	// Resize the application surface
	surface_resize(application_surface, winW, winH);
	
	// Resize the hidden pixel buffer/surface
	if (!variable_instance_exists(id, "pxBuffer")) {
		pxBuffer = buffer_create(winW * winH * 4, buffer_fast, 1);	
	}		
	buffer_resize(pxBuffer, winW * winH * 4);	
	
	if (!surface_exists(pxSurface)) {
		pxSurface = surface_create(winW, winH);
	}
	surface_resize(pxSurface, winW, winH);
	
	// Resize the selection outline surface
	if (!surface_exists(surfSelectionOutline)) {
		surfSelectionOutline = surface_create(winW, winH);
	}
	surface_resize(surfSelectionOutline, winW, winH);
	
	scr_update_pxsurface();
}