function UiSwitch(style = {}, props = {}) : UiNode(style, props) constructor {
    self.flexDirection = "row";
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.row);
    self.alignItems = "center";
    
    setName(props[$ "name"] ?? "UiSwitch");
    self.value = props[$ "value"] ?? false;
    self.label = props[$ "label"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(value, input) {};
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    
    self.pointerEvents = true;
    self.handpoint = true;
    
    // Input node first (the visual track)
    self.Input = new UiNode({
        name: "UiSwitch.Input", 
        width: 36,
        height: 20,
        marginRight: 12
    });
    self.add(self.Input);
    
    // Label node second
    if (self.label != undefined) {
        self.Label = new UiText(self.label, {}, { color: "main" });
        self.add(self.Label);
    }
    
    // Animation state
    self.animThumbPos = self.value ? 1 : 0;
    
    with (self.Input) {
        self.onDraw = function() {
            var p = self.parent;
            
            var h = (self.y2 - self.y1);
            var r = h / 2;
            
            // Track
            var trackColor = merge_color(global.UI_COL_BORDER, global.UI_COL_PRIMARY, p.animThumbPos);
            if (p.hovered && !p.value) trackColor = global.UI_COL_BTN_HOVER;
            
            draw_set_color(trackColor);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, r, r, false);
            
            // Thumb
            var thumbR = r - 3;
            var thumbX = lerp(self.x1 + r, self.x2 - r, p.animThumbPos);
            var thumbY = ~~mean(self.y1, self.y2);
            
            draw_set_color(c_white);
            draw_circle(thumbX, thumbY, thumbR, false);
        };
    }
    
    self.onStep(function() {
        if (self.valueGetter != undefined) self.value = self.valueGetter();
        
        var targetPos = self.value ? 1 : 0;
        self.animThumbPos += (targetPos - self.animThumbPos) * 0.3;
        if (abs(self.animThumbPos - targetPos) > 0.01) global.UI.requestRedraw();
    });
    
    self.onClick(function() {
        self.value = !self.value;
        self.onChange(self.value, self);
        global.UI.requestRedraw();
        return true;
    });
}

