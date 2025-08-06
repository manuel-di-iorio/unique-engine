// #52B9B9 cyan
// #F012BE magenta

function UiButton(textOrImage, style = {}, props = {}): UiNode(style, props) constructor {
    text = undefined;
    sprite = undefined;
    onClick = function() {};
    autoResize = props[$ "autoResize"] ?? true;
    self.textOrImage = textOrImage;
    
    // Set the size of the button
    if (autoResize) {
        var _w, _h;
        if (is_string(textOrImage)) {
            draw_set_font(fText)
            _w = string_width(textOrImage) + 10;
            _h = string_height(textOrImage) + 5;
        } else {
            _w = sprite_get_width(textOrImage);
            _h = sprite_get_height(textOrImage);
        }
        setSize(_w, _h);
    }
    
    function draw(x1, y1, x2, y2, hovered, xp1, yp1, xp2, yp2) {
        if (hovered) {
            draw_set_color(#282A36);
            draw_rectangle(xp1, yp1, xp2, yp2, false);
            
            if (mouse_check_button_released(mb_left)) onClick();
        }
        
        draw_set_color(#191A21);
        draw_rectangle(xp1, yp1, xp2, yp2, true);
        
        var xm = ~~mean(x1, x2);
        var ym = ~~mean(y1, y2);
        
        if (text != undefined) {
            // Draw text
            draw_set_font(fText); draw_set_color(c_white); draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_text(xm, ym, textOrImage);
        } else {
            // Draw sprite
            _subimg = hovered ? 1 : 0;
            draw_sprite(textOrImage, _subimg, xm, ym);
        }
    }
}