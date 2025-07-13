var str = $"Press B to toggle the bounding box{chr(13) + chr(10)}Press W to toggle the wireframe";
draw_set_color(#222222); draw_set_valign(fa_bottom);
draw_text(20+1, window_get_height()-20-1, str);
draw_set_color(#881111);
draw_text(20, window_get_height()-20, str);