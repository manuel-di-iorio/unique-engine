function UiTooltip() : UiNode({
    name: "UiTooltip",
    position: "absolute",
    padding: 3,
    paddingLeft: 6,
    paddingRight: 6,
    border: true,
    display: "none" // Hidden by default
}) constructor {
    self.backgroundColor = #282a36;
    self.borderColor = #44475a;
    self.borderRadius = 4;

    self.textNode = new UiText("", {}, { color: #f8f8f2, font: fTextSmall });
    self.add(self.textNode);
    
    self.target = undefined;
    
    // Override show to accept target and text
    self.show = function(target, text) {
        self.target = target;
        self.textNode.text = text;
        self.textNode.computeSize();
        
        // Force size update on tooltip itself to match text (plus padding)
        
        // Show logic (inlined from UiNode)
        flexpanel_node_style_set_display(self.node, flexpanel_display.flex);
        self.display = true;
        
        // Calculate initial position immediately
        if (self.target != undefined) {
             var estimatedWidth = self.textNode.getWidth() + 16; // 8 padding left + 8 padding right
             var tx = self.target.x1 + (self.target.width / 2) - (estimatedWidth / 2);
             var ty = self.target.y2 + 8;
             
             self.setLeft(tx);
             self.setTop(ty);
        }
        
        global.UI.needsUpdate = true;
    };
    
    self.hide = function() {
        // Hide logic (inlined from UiNode)
        flexpanel_node_style_set_display(self.node, flexpanel_display.none);
        self.display = false;
        global.UI.needsUpdate = true;
        
        self.target = undefined;
    };
    
    // Update position to stay centered on target
    self.onStep(function() {
        if (self.display && self.target != undefined) {
            // Calculate centered position
            // Use actual width if available, otherwise fall back to estimate
            var currentWidth = self.width > 0 ? self.width : (self.textNode.getWidth() + 16);
            var tx = self.target.x1 + (self.target.width / 2) - (currentWidth / 2);
            var ty = self.target.y2 + 8;
            
            // Keep within screen bounds
            var winW = window_get_width();
            var winH = window_get_height();
            
            // Ensure we have dimensions
            if (currentWidth > 0) {
                tx = clamp(tx, 5, winW - currentWidth - 5);
                ty = clamp(ty, 5, winH - (self.height > 0 ? self.height : 30) - 5);
                
                // Only update if changed to avoid constant layout invalidation
                if (abs(self.getLeft() - tx) > 1) self.setLeft(tx);
                if (abs(self.getTop() - ty) > 1) self.setTop(ty);
            }
        }
    });
    
    // Custom draw to handle background and text
    self.onDraw = function() {
        // Background
        draw_set_color(self.backgroundColor);
        draw_roundrect(self.x1, self.y1, self.x2, self.y2, false);
        
        // Border
        draw_set_color(self.borderColor);
        draw_roundrect(self.x1, self.y1, self.x2, self.y2, true);
    };
}
