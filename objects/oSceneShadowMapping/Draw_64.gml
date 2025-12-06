var _x = display_get_gui_width() - 260;
var _y = display_get_gui_height() - 260;
shadowMapViewer.render(camera, _x, _y);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(_x + 4, _y + 2, "Shadow Map");
