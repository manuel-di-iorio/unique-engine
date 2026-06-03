function UiButton(textOrImage, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiButton");
    self.text = undefined;
    self.sprite = undefined;
    self.label = props[$ "label"]; // Text label to show alongside sprite
    self.style = style;
    self.autoResize = props[$ "autoResize"] ?? (style[$ "width"] == undefined && style[$ "height"] == undefined) ?? true;
    self.outline = props[$ "outline"] ?? false;
    self.pointerEvents = true;
    self.halign = props[$ "halign"] ?? fa_center;
    self.handpoint = true;
    self.selected = false;
    self.enabled = true;
    self.enableRipple = props[$ "enableRipple"] ?? true;
    self.variant = props[$ "variant"] ?? "secondary"; // primary, secondary, outline, ghost, danger
    
    self.onMouseEnter(function() {
        global.UI.requestRedraw();
    });
    
    self.onMouseLeave(function() {
        global.UI.requestRedraw();
    });
    
    self.ripples = [];
    
    self.onClick(function() {
        if (!self.enabled) return;
        if (!self.enableRipple) return;
        
        var mx = window_mouse_get_x();
        var my = window_mouse_get_y();
        
        var w = self.x2 - self.x1;
        var h = self.y2 - self.y1;
        var maxR = sqrt(w*w + h*h) * 1.2;
        
        array_push(self.ripples, {
            x: mx,
            y: my,
            radius: 0,
            alpha: 0.3,
            maxRadius: maxR
        });
        global.UI.requestRedraw();
    });
    
    function resize() {
        var _w = 0, _h = 0;
        if (self.text != undefined) {
            draw_set_font(fText);
            _w = string_width(self.text) + 24;
            _h = string_height(self.text) + 12;
        } else if (self.sprite != undefined && self.label != undefined) {
            draw_set_font(fText);
            _w = sprite_get_width(self.sprite) + string_width(self.label) + 30;
            _h = max(sprite_get_height(self.sprite), string_height(self.label)) + 12;
        } else if (self.sprite != undefined) {
            _w = sprite_get_width(self.sprite) + 16;
            _h = sprite_get_height(self.sprite) + 16;
        } else {
            _w = 32;
            _h = 32;
        }
        
        // Ensure minimum dimensions to prevent overlap issues
        _w = max(_w, 40);
        _h = max(_h, 24);
        
        if (self.autoResize || self.style[$ "width"] == undefined) {
            self.setWidth(_w);
        }
        if (self.autoResize || self.style[$ "height"] == undefined) {
            self.setHeight(_h);
        }
    }
    
    function setEnabled(enabled) {
        self.enabled = enabled;
        self.pointerEvents = enabled;
        global.UI.requestRedraw();
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
        var radius = 6;
        
        var bg_color = global.UI_COL_BG_CARD;
        var text_color = global.UI_COL_TEXT_MAIN;
        var hover_color = global.UI_COL_BTN_HOVER;
        var border_color = global.UI_COL_BORDER;
        var ripple_color = c_white;
        
        if (self.variant == "primary") {
            bg_color = global.UI_COL_PRIMARY;
            hover_color = global.UI_COL_PRIMARY_HOVER;
            text_color = c_white;
            border_color = undefined;
        } else if (self.variant == "outline") {
            bg_color = global.UI_COL_BG_CARD;
            hover_color = global.UI_COL_BTN_HOVER;
            text_color = global.UI_COL_TEXT_MAIN;
            border_color = global.UI_COL_BORDER;
            ripple_color = merge_color(global.UI_COL_TEXT_MAIN, c_black, 0.15);
        } else if (self.variant == "ghost") {
            bg_color = -1;
            hover_color = global.UI_COL_BTN_HOVER;
            text_color = global.UI_COL_TEXT_DIM;
            border_color = undefined;
            ripple_color = merge_color(global.UI_COL_TEXT_MAIN, c_black, 0.15);
        } else if (self.variant == "danger") {
            bg_color = global.UI_COL_DANGER;
            hover_color = #DC2626;
            text_color = c_white;
            border_color = undefined;
        } else {
            ripple_color = merge_color(global.UI_COL_TEXT_MAIN, c_black, 0.15);
        }
        
        if (self.selected) {
            bg_color = global.UI_COL_PRIMARY;
            text_color = c_white;
        }
        
        // Disabled dimming
        var _alpha = self.enabled ? 1 : 0.35;
        draw_set_alpha(_alpha);

        // Background
        if (bg_color != -1) {
            draw_set_color(self.hovered ? hover_color : bg_color);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, radius, radius, false);
        } else if (self.hovered) {
            draw_set_color(hover_color);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, radius, radius, false);
        }
        
        // Border
        if (border_color != undefined || self.outline) {
            draw_set_color(border_color ?? global.UI_COL_BORDER);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, radius, radius, true);
        }
        
        // Ripples
        if (array_length(self.ripples) > 0) {
            var _scissor = gpu_get_scissor();
            __uui_set_scissor(self.x1, self.y1, self.x2 - self.x1, self.y2 - self.y1);
            var dt_scale = clamp((delta_time / 1000000) * 60, 0.1, 4.0);
            for (var i = array_length(self.ripples) - 1; i >= 0; i--) {
                var r = self.ripples[i];
                r.radius += 3 * dt_scale;
                r.alpha -= 0.015 * dt_scale;
                draw_set_alpha(max(0, r.alpha));
                draw_set_color(ripple_color);
                draw_circle(r.x, r.y, r.radius, false);
                if (r.alpha <= 0) array_delete(self.ripples, i, 1);
            }
            gpu_set_scissor(_scissor);
            draw_set_alpha(_alpha);
            if (array_length(self.ripples) > 0) global.UI.requestRedraw();
        }
        
        var xm;
        switch (self.halign) {
            case fa_left: xm = self.x1 + 12; break;
            case fa_center: xm = ~~mean(self.x1, self.x2); break;
            case fa_right: xm = self.x2 - 12; break;
        } 
        
        var ym = ~~mean(self.y1, self.y2);
        
        if (self.text != undefined) {
            draw_set_font(fText); draw_set_color(text_color); draw_set_halign(self.halign); draw_set_valign(fa_middle);
            draw_text(xm, ym, self.text);
        } else if (self.sprite != undefined && self.label != undefined) {
            var spriteWidth = sprite_get_width(self.sprite);
            var totalWidth = spriteWidth + string_width(self.label) + 8;
            var startX = self.x1 + (self.x2 - self.x1 - totalWidth) / 2;
            draw_sprite_ext(self.sprite, self.hovered ? 1 : 0, startX + spriteWidth / 2, ym, 1, 1, 0, text_color, 1);
            draw_set_font(fText); draw_set_color(text_color); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_text(startX + spriteWidth + 8, ym, self.label);
        } else if (self.sprite) {
            draw_sprite_ext(self.sprite, self.hovered ? 1 : 0, xm, ym, 1, 1, 0, text_color, 1);
        }

        draw_set_alpha(1);
    }
    
    // Set the text/sprite and resize the button if specified
    if (textOrImage != undefined) {
        if (is_string(textOrImage)) {
            self.text = textOrImage;
        } else {
            self.sprite = textOrImage;
        }
        
        self.resize();
    }
}
