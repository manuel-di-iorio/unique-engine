function scrDemoDrawSelector() {
    if (mouse_check_button_pressed(mb_left) && device_mouse_x_to_gui(0) < selectorW) {
       selectorMouseStart = true;
    }
    
    draw_set_color(#080808);
    draw_rectangle(0, 0, selectorW, view_hport, false);
    draw_set_color(#111111); draw_set_alpha(.2);
    draw_rectangle(300, 0, selectorW+3, view_hport, false);
    draw_set_alpha(1);
    
    var x1 = 10;
    var yy = 70;
    var x2 = selectorW-10;
    var h = 30;
    var isHovering = false;
    var btnCol;
    
    for (var i=0, l=array_length(scenes); i<l; i++) {
        var scene = scenes[i];
        
        var ym = yy + h/2;
        var yf = yy + h;
        
        var hover = point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), x1, yy, x2, yf);
        
        if (currentDemoIdx == i) {
            btnCol = #CC00CC;
        } else {
            if (hover) {
                isHovering = true;
                
                if (mouse_check_button_released(mb_left) && selectorMouseStart) {
                    btnCol = #3377FF;
                    setScene(i);
                    
                } else {
                    btnCol = #1155DD;
                }
            } else {
                btnCol = #444444;
            }
        }
        
        // Button
        draw_set_color(btnCol);
        draw_rectangle(x1, yy, x2, yf, false);
        draw_set_color(#222222);
        draw_rectangle(x1, yy, x2, yf, true);
        
        // Text
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(x1 + 10, ym, scene.name);
        yy += h + 6;
    }
    
    window_set_cursor(isHovering ? cr_handpoint : cr_default);
    
    if (mouse_check_button_released(mb_left)) {
        selectorMouseStart = false;
    }
}