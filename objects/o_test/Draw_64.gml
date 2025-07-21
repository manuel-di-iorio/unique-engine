var str = $"Scene: {demo+1}/{demoMax+1}. Use the Page UP/DOWN keys to switch scene";
draw_set_color(#111111); draw_set_alpha(.6);
draw_rectangle(10, 23, window_get_width() - 10, 47, false);
draw_set_alpha(1); draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text(20, 25, str);