/**
 * Do actions after something in the scene/camera changes
 */
function scr_on_scene_transform() {
	gpu_set_fog(false, 0, 0, 0);
	
	// Update the pixel selection surface
	scr_update_pxsurface();
	
	scr_fog_enable();
}