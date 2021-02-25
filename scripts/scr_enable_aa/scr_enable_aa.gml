function scr_enable_aa() {
	if (!aaEnabled) return;
	
	if (display_aa > 8) {
		display_reset(8, false);
	} else if (display_aa > 4) {
		display_reset(4, false);
	} else if (display_aa > 0) {
		display_reset(2, false);
	} else {
		display_reset(0, false);
	}
}