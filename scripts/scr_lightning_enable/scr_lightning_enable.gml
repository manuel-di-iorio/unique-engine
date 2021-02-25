function scr_lightning_enable() {
	if (!settings.camera.lightning) return;
	draw_set_lighting(true);
}