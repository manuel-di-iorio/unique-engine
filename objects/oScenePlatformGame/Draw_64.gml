// Disegna interfaccia UI
draw_set_color(c_white);
draw_set_font(fDemoUI);
draw_set_halign(fa_right);
draw_set_valign(fa_top);

var txt = "COLLECTED OBJECTS: " + string(collectedCount) + " / " + string(totalCollectibles);
draw_text(display_get_gui_width() - 20, 20, txt);

if (collectedCount == totalCollectibles) {
    draw_set_color(c_yellow);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(view_xport[0] + view_hport[0] / 2, display_get_gui_height() / 2, "YOU WIN!");
}
