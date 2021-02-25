function scr_enable_aa() {
	var aa = settings.display.aa;
	var vsync = settings.display.vsync;
	
	if (aa != -1) {
		display_reset(aa, vsync);
		return;
	}
	
	// Auto set AA based on display capabilities
	if (display_aa > 8) {
		display_reset(8, vsync);
	} else if (display_aa > 4) {
		display_reset(4, vsync);
	} else if (display_aa > 0) {
		display_reset(2, vsync);
	} else {
		display_reset(0, vsync);
	}
}