draw_set_halign(fa_right); draw_set_valign(fa_top);
draw_text(display_get_gui_width() - 10, 10, "A directional light is rotating around the object");

shadowMapViewer.render(camera, display_get_gui_width() - 260, display_get_gui_height() - 260);
