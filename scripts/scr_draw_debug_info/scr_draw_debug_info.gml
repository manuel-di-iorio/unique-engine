function scr_draw_debug_info() {
	draw_text(20, winH - 220, "Camera pos: " + string(x) + ", " + string(y) + ", " + string(z));
	draw_text(20, winH - 200, "Camera dir: " + string(direction) + " - zdir: " + string(zdir));
	draw_text(20, winH - 180, "Selected px: " + string(selectedPxCol));
	
	draw_text(20, winH - 120, "Models: " + string(o_ctrl.stats.models));
	draw_text(20, winH - 100, "Meshes: " + string(o_ctrl.stats.meshes));
	draw_text(20, winH -80, "Triangles: " + string(o_ctrl.stats.triangles));
	draw_text(20, winH -60, "Lights: " + string(o_ctrl.stats.lights));
	draw_text(20, winH -40, "Audio sources: " + string(o_ctrl.stats.audioSources));
}