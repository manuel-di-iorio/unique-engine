draw_set_halign(fa_center); draw_set_valign(fa_middle);

if (modelLoading) {
    draw_text(view_xport + view_wport/2, view_hport/2, $"Loading model..{chr(13) + chr(10)}Please wait, it will take around 2-4 minutes")
} else if (!modelLoaded) { 
    draw_text(view_xport + view_wport/2, view_hport/2, $"Press space to load the .obj model")
}