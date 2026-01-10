
// Shadow
var _x = view_wport[1] + 20;
var _y = display_get_gui_height() - 200;
pointShadowMapViewer.render(camera, _x, _y);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(_x, _y - 25, "Point Shadow Map");


// Directional
// _x = display_get_gui_width() - 200;
// dirShadowMapViewer.render(camera, _x, _y);

// draw_set_halign(fa_left);
// draw_set_valign(fa_top);
// draw_set_color(c_white);
// draw_text(_x, _y - 25, "Dir Shadow Map");
