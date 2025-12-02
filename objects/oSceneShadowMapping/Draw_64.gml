draw_set_halign(fa_right); draw_set_valign(fa_top);
draw_text(display_get_gui_width() - 10, 10, "A directional light is rotating around the object");

// Debug: Draw shadow map in bottom-left corner
//if (dirLight.castShadow && surface_exists(dirLight.shadow.map.surface)) {
    //draw_surface_ext(dirLight.shadow.map.surface, display_get_gui_width() - 220, display_get_gui_height() - 220, 0.2, 0.2, 0, c_white, 1);
    //draw_set_halign(fa_left); draw_set_valign(fa_top);
    //draw_text(display_get_gui_width() - 220, display_get_gui_height() - 245, "Shadow Map:");
//}
