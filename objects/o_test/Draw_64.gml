var str = $"Scene: {demo+1}/{demoMax+1}. Use the W/S keys to switch scene{chr(13)+chr(10)}FPS: {fps_real}"
draw_set_color(c_dkgray);
draw_text(20+1, 20+1, str);
draw_set_color(#881111);
draw_text(20, 20, str);