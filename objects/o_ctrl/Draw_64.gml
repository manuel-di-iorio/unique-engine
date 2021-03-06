gpu_set_fog(false, 0, 0, 0); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(-1);

// Draw the selection outline surface
if (selectedObj != -1 && selectedObj.type == ObjectType.model && surface_exists(surfSelectionOutline)) {
	 draw_surface(surfSelectionOutline, 0, 0);
}

//if (surface_exists(pxSurface)) draw_surface(pxSurface, 0, 0); // @debug

scr_draw_debug_info();

/*
// @debug
for (var i=0; i<ds_list_size(history_list); i++) {
	var action = history_list[| i];
	var obj = action.object;
	var state = action.state;
	if (i == history_index) {
		draw_set_color(c_yellow)
	} else {
		draw_set_color(c_white)
	}
	draw_text(20, 40+i*20, string(obj.selectionId) + ": " + string(state.x) + "," + string(state.y) + "," +string(state.z));
	draw_set_color(c_white)
}
*/

// Draw the HUD axis icon
if (surface_exists(surfHudAxis)) draw_surface(surfHudAxis, winW-110, 5);

// Draw the mouse cursor
if (cursorSprite != -1) draw_sprite(cursorSprite, 0, winMouseX, winMouseY);

scr_fog_enable();