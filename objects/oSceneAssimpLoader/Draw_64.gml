var str = $"Model loaded in {loadTime}ms{chr(13) + chr(10)}Press B to toggle the bounding box{chr(13) + chr(10)}Press W to toggle the wireframe";
draw_set_halign(fa_right); draw_set_valign(fa_bottom); draw_set_color(c_white);
draw_text(view_xport + view_wport - 20, view_hport - 20, str);