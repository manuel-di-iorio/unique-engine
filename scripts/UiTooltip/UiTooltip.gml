function UiTooltip(): UiNode({
    name: "UiTooltip",
    position: "absolute",
    padding: 3,
    paddingLeft: 6,
    paddingRight: 6,
    border: true,
    left: -9999, 
    top: -9999,
    display: "none" // Hidden by default
}, { visible: false }) constructor {
    self.backgroundColor = #282a36;
    self.borderColor = #44475a;
    self.borderRadius = 4;

    self.textNode = new UiText("", {}, { color: #f8f8f2, font: fTextSmall });
    self.add(self.textNode);
    
    self.target = undefined;
    self.isPositioned = false;
    
    self.show = function(target, text) {
        self.target = target;
        self.textNode.text = text;
        self.textNode.computeSize();
        
        // Calculate initial position based on cursor
        var tx = global.UI.mouseX + 15;
        var ty = global.UI.mouseY + 20;
        
        self.setLeft(tx);
        self.setTop(ty);
        
        // Show logic
        flexpanel_node_style_set_display(self.node, flexpanel_display.flex);
        self.display = true;
        self.visible = true; // Show immediately
        global.UI.requestUpdate();
    };
    
    self.hide = function() {
        self.layout.left = -9999;
        self.layout.top = -9999;
        self.x1 = -9999;
        self.y1 = -9999;
        self.x2 = -9999;
        self.y2 = -9999;
        
        global.UI.removeElementFromTree(self);

        flexpanel_node_style_set_display(self.node, flexpanel_display.none);
        self.display = false;
        self.visible = false;
        self.target = undefined;
    };
    
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
