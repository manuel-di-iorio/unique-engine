function scr_fog_enable() {
	if (!settings.camera.fog) return;
	gpu_set_fog(true, o_ctrl.fogcolor, o_ctrl.fogstart, o_ctrl.fogend);
}