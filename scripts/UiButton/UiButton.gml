function UiButton(textOrImage, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiButton");
    self.text = undefined;
    self.sprite = undefined; 
    autoResize = props[$ "autoResize"] ?? true;
    self.outline = props[$ "outline"] ?? false;
    self.pointerEvents = true;
    
    onMouseEnter(function() {
       if (window_get_cursor() == cr_default) {
           window_set_cursor(cr_handpoint);
       }
    });
    
    onMouseLeave(function() {
        window_set_cursor(cr_default);
    });
    
    function resize() {
        var _w, _h;
        if (self.text != undefined) {
            draw_set_font(fText)
            _w = string_width(self.text) + 10;
            _h = string_height(self.text) + 5;
        } else {
            _w = sprite_get_width(self.sprite);
            _h = sprite_get_height(self.sprite);
        }
        setSize(_w, _h);
    }
    
    function setText(text) {
        self.text = text;
        self.resize();
    }
    
    function setSprite(sprite) {
        self.sprite = sprite;
        self.resize();
    }
    
    function onDraw() {
        if (self.hovered) {
            draw_set_color(global.UI_COL_BTN_HOVER);
            draw_rectangle(self.xp1, self.yp1, self.xp2, self.yp2, false);
        }
        
        if (!self.outline) {
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.xp1, self.yp1, self.xp2, self.yp2, true);
        }
        
        var xm = ~~mean(self.x1, self.x2);
        var ym = ~~mean(self.y1, self.y2);
        
        if (self.text != undefined) {
            // Draw text
            draw_set_font(fText); draw_set_color(c_white); draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_text(xm, ym, self.text);
        } else {
            // Draw sprite
            draw_sprite(self.sprite, self.hovered ? 1 : 0, xm, ym);
        }
    }
    
    // Set the text/sprite and resize the button if specified
    if (is_string(textOrImage)) {
        self.text = textOrImage;
    } else {
        self.sprite = textOrImage;
    }
    
    if (autoResize) self.resize();
}