draw_set_halign(fa_right); draw_set_color(c_white);
//draw_text(view_xport + view_wport - 20, view_yport + view_hport - 40, $"Q = View Tool, W = Move Tool, E = Rotate Tool, R = Scale Tool{chr(13) + chr(10)}T = Toggle world/local space{chr(13) + chr(10)}Current tool: {tool}");

draw_text(view_xport + view_wport - 20, view_yport + view_hport - 40, $"Q = View Tool, W = Move Tool, E = Rotate Tool{chr(13) + chr(10)}Current tool: {tool}");
