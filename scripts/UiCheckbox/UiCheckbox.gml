function UiCheckbox(style = {}, props = {}) : UiNode(style, props) constructor {
    setName(props[$ "name"] ?? "UiCheckbox");
    self.value = props[$ "value"] ?? false;
    self.label = props[$ "label"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(input, value) {};
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    
    var _marginLeft = self.label == undefined ? 0 : 3 + string_width(self.label) + 20;
    
    self.Input = new UiNode({
        name: "UiCheckbox.Input", 
        marginLeft: _marginLeft,
        width: 18,
        height: 18
    });
    self.add(self.Input);
    
    self.onClick(function() {
        self.parent.click();
    });
    
    with (self.Input) {
        self.pointerEvents = true;
        
        self.onMouseEnter(function() {
           if (window_get_cursor() == cr_default) {
               window_set_cursor(cr_handpoint);
           }
        });
        
        self.onMouseLeave(function() {
            window_set_cursor(cr_default);
        });
        
        self.onDraw = function() {
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
            
            if (self.hovered) {
                draw_set_color(global.UI_COL_CHECKBOX_HOVER);
                draw_rectangle(self.x1-1, self.y1-1, self.x2+1, self.y2+1, true);
            }
            
            if (self.parent.value) {
                draw_sprite(sprUiCheckTick, 0, ~~mean(self.x1, self.x2), ~~mean(self.y1, self.y2));
            }
        };
    }
    
    // Update value from external source
    function onStep() {
        if (self.valueGetter != undefined) self.value = self.valueGetter();
    }
    
    self.onClick(function() {
        self.value = !self.value;
        self.onChange(self.value, self);
    });
    
    // Draw label if present
    function onDraw() {
        if (self.label != undefined) {
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_text(self.x1 + 3, ~~mean(self.y1, self.y2), self.label);
        }
    }
}