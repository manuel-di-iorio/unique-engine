function UiButton(textOrImage, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiButton");
    self.text = undefined;
    self.sprite = undefined;
    self.label = props[$ "label"]; // Text label to show alongside sprite
    self.autoResize = props[$ "autoResize"] ?? (style[$ "width"] == undefined && style[$ "height"] == undefined) ?? true;
    self.outline = props[$ "outline"] ?? false;
    self.pointerEvents = true;
    self.halign = props[$ "halign"] ?? fa_center;
    self.handpoint = true;
    
    self.onMouseEnter(function() {
        global.UI.needsRedraw = true;
    });
    
    self.onMouseLeave(function() {
        global.UI.needsRedraw = true;
    });
    
    function resize() {
        var _w, _h;
        if (self.text != undefined) {
            draw_set_font(fText)
            _w = string_width(self.text) + 10;
            _h = string_height(self.text) + 5;
        } else if (self.sprite != undefined && self.label != undefined) {
            // Sprite + label
            draw_set_font(fText);
            _w = sprite_get_width(self.sprite) + string_width(self.label) + 20;
            _h = max(sprite_get_height(self.sprite), string_height(self.label)) + 10;
        } else if (self.sprite != undefined) {
            _w = sprite_get_width(self.sprite);
            _h = sprite_get_height(self.sprite);
        } else {
            _w = 32;
            _h = 32;
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

        var xm;
        switch (self.halign) {
            case fa_left: xm = self.x1; break;
            case fa_center: xm = ~~mean(self.x1, self.x2); break;
            case fa_right: xm = self.x2; break;
        } 
        
        var ym = ~~mean(self.y1, self.y2);
        
        if (self.text != undefined) {
            // Draw text only
            draw_set_font(fText); draw_set_color(c_white); draw_set_halign(self.halign); draw_set_valign(fa_middle);
            draw_text(xm, ym, self.text);
        } else if (self.sprite != undefined && self.label != undefined) {
            // Draw sprite + label
            var spriteWidth = sprite_get_width(self.sprite);
            var totalWidth = spriteWidth + string_width(self.label) + 8;
            var startX = self.x1 + (self.x2 - self.x1 - totalWidth) / 2;
            
            draw_sprite(self.sprite, self.hovered ? 1 : 0, startX + spriteWidth / 2, ym);
            
            draw_set_font(fText); draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_text(startX + spriteWidth + 8, ym, self.label);
        } else if (self.sprite) {
            // Draw sprite only
            draw_sprite(self.sprite, self.hovered ? 1 : 0, xm, ym);
        }
    }
    
    // Set the text/sprite and resize the button if specified
    if (textOrImage != undefined) {
        if (is_string(textOrImage)) {
            self.text = textOrImage;
        } else {
            self.sprite = textOrImage;
        }
        
        if (autoResize) self.resize();
    }
}
