function UiSlider(style = {}, props = {}) : UiNode(style, props) constructor {
    setName(props[$ "name"] ?? "UiSlider");
    self.value = props[$ "value"] ?? 0;
    self.valueStart = props[$ "valueStart"] ?? undefined;
    self.valueEnd = props[$ "valueEnd"] ?? undefined;
    self.minValue = props[$ "min"] ?? 0;
    self.maxValue = props[$ "max"] ?? 100;
    self.onChange = props[$ "onChange"] ?? function(value, input) {};
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    self.step = props[$ "step"] ?? 1;
    
    self.pointerEvents = true;
    self.handpoint = true;
    
    // For smooth drawing
    self.animValue = self.value;
    self.animValueStart = self.valueStart;
    self.animValueEnd = self.valueEnd;
    
    // Range mode
    self.isRange = (self.valueStart != undefined && self.valueEnd != undefined);
    self.draggingThumb = 0; // 0 = none, 1 = start, 2 = end
    
    self.onMouseEnter(function() { global.UI.requestRedraw(); });
    self.onMouseLeave(function() { global.UI.requestRedraw(); });
    
    self.onDraw = function() {
        if (self.isRange) {
            self.animValueStart += (self.valueStart - self.animValueStart) * 0.3;
            self.animValueEnd += (self.valueEnd - self.animValueEnd) * 0.3;
            if (abs(self.animValueStart - self.valueStart) > 0.01 || abs(self.animValueEnd - self.valueEnd) > 0.01) global.UI.requestRedraw();
        } else {
            self.animValue += (self.value - self.animValue) * 0.3;
            if (abs(self.animValue - self.value) > 0.01) global.UI.requestRedraw();
        }
        
        var cy = ~~mean(self.y1, self.y2);
        var trackH = 4;
        
        // Background track
        draw_set_color(global.UI_COL_BORDER);
        draw_roundrect_ext(self.x1, cy - trackH/2, self.x2, cy + trackH/2, trackH/2, trackH/2, false);
        
        // Fill track
        if (self.isRange) {
            var t1 = clamp((self.animValueStart - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var t2 = clamp((self.animValueEnd - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var fillX1 = lerp(self.x1, self.x2, t1);
            var fillX2 = lerp(self.x1, self.x2, t2);
            
            if (fillX2 > fillX1) {
                draw_set_color(global.UI_COL_PRIMARY);
                draw_roundrect_ext(fillX1, cy - trackH/2, fillX2, cy + trackH/2, trackH/2, trackH/2, false);
            }
        } else {
            var t = clamp((self.animValue - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var fillX = lerp(self.x1, self.x2, t);
            
            if (fillX > self.x1) {
                draw_set_color(global.UI_COL_PRIMARY);
                draw_roundrect_ext(self.x1, cy - trackH/2, fillX, cy + trackH/2, trackH/2, trackH/2, false);
            }
        }
        
        // Draw thumbs
        var thumbR = 8;
        if (self.hovered || self.draggingThumb != 0) thumbR = 10;
        
        if (self.isRange) {
            var t1 = clamp((self.animValueStart - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var t2 = clamp((self.animValueEnd - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var x1 = lerp(self.x1, self.x2, t1);
            var x2 = lerp(self.x1, self.x2, t2);
            
            // Start thumb
            draw_set_color(c_white);
            draw_circle(x1, cy, thumbR, false);
            draw_set_color(#94A3B8);
            draw_circle(x1, cy, thumbR, true);
            
            // End thumb
            draw_set_color(c_white);
            draw_circle(x2, cy, thumbR, false);
            draw_set_color(#94A3B8);
            draw_circle(x2, cy, thumbR, true);
            
            // Hover ring
            if (self.hovered || self.draggingThumb != 0) {
                draw_set_color(global.UI_COL_PRIMARY);
                draw_set_alpha(0.2);
                if (self.draggingThumb == 1) draw_circle(x1, cy, thumbR + 4, false);
                else if (self.draggingThumb == 2) draw_circle(x2, cy, thumbR + 4, false);
                draw_set_alpha(1.0);
            }
        } else {
            var t = clamp((self.animValue - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var fillX = lerp(self.x1, self.x2, t);
            
            draw_set_color(c_white);
            draw_circle(fillX, cy, thumbR, false);
            draw_set_color(#94A3B8);
            draw_circle(fillX, cy, thumbR, true);
            
            if (self.hovered || self.draggingThumb != 0) {
                draw_set_color(global.UI_COL_PRIMARY);
                draw_set_alpha(0.2);
                draw_circle(fillX, cy, thumbR + 4, false);
                draw_set_alpha(1.0);
            }
        }
    };
    
    self.onStep(function() {
        if (self.valueGetter != undefined && !self.dragging) {
            self.value = self.valueGetter();
        }
    });
    
    function updateValueFromMouse() {
        var mx = window_mouse_get_x();
        var t = clamp((mx - self.x1) / (self.x2 - self.x1), 0, 1);
        var rawVal = lerp(self.minValue, self.maxValue, t);
        
        if (self.step > 0) {
            rawVal = round(rawVal / self.step) * self.step;
        }
        rawVal = clamp(rawVal, self.minValue, self.maxValue);
        
        if (self.isRange) {
            if (self.draggingThumb == 1) {
                // Update start thumb
                if (rawVal > self.valueEnd) rawVal = self.valueEnd;
                if (self.valueStart != rawVal) {
                    self.valueStart = rawVal;
                    self.onChange([self.valueStart, self.valueEnd], self);
                    global.UI.requestRedraw();
                }
            } else if (self.draggingThumb == 2) {
                // Update end thumb
                if (rawVal < self.valueStart) rawVal = self.valueStart;
                if (self.valueEnd != rawVal) {
                    self.valueEnd = rawVal;
                    self.onChange([self.valueStart, self.valueEnd], self);
                    global.UI.requestRedraw();
                }
            }
        } else {
            if (self.value != rawVal) {
                self.value = rawVal;
                self.onChange(self.value, self);
                global.UI.requestRedraw();
            }
        }
    }
    
    self.onMouseDown(function() {
        if (self.isRange) {
            var mx = window_mouse_get_x();
            var cy = ~~mean(self.y1, self.y2);
            var t1 = clamp((self.valueStart - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var t2 = clamp((self.valueEnd - self.minValue) / (self.maxValue - self.minValue), 0, 1);
            var x1 = lerp(self.x1, self.x2, t1);
            var x2 = lerp(self.x1, self.x2, t2);
            
            // Check which thumb is closer
            var dist1 = abs(mx - x1);
            var dist2 = abs(mx - x2);
            
            if (dist1 < dist2) {
                self.draggingThumb = 1;
            } else {
                self.draggingThumb = 2;
            }
        } else {
            self.dragging = true;
        }
        updateValueFromMouse();
        return true;
    });
    
    self.onStep(function() {
        if (self.isRange) {
            if (self.draggingThumb != 0) {
                if (!mouse_check_button(mb_left)) {
                    self.draggingThumb = 0;
                    global.UI.requestRedraw();
                } else {
                    updateValueFromMouse();
                }
            }
        } else {
            if (self.dragging) {
                if (!mouse_check_button(mb_left)) {
                    self.dragging = false;
                    global.UI.requestRedraw();
                } else {
                    updateValueFromMouse();
                }
            }
        }
    });
}
