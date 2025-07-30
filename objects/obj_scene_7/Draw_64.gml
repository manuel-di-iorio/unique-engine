if (!modelLoaded) {
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text(room_width/2, room_height/2, $"Press space to load the .obj model{chr(13)+chr(10)}(it will take around 1-3 minutes)")
}