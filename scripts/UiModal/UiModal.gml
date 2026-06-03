/// @desc UiModal — an overlay dialog box.
/// @param {Struct} style
/// @param {Struct} props
function UiModal(style = {}, props = {}) : UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiModal");
    
    // Override the size to cover the screen entirely
    flexpanel_node_style_set_width(self.node, 100, flexpanel_unit.percent);
    flexpanel_node_style_set_height(self.node, 100, flexpanel_unit.percent);
    flexpanel_node_style_set_position_type(self.node, flexpanel_position_type.absolute);
    self.setLeft(0);
    self.setTop(0);
    flexpanel_node_style_set_justify_content(self.node, flexpanel_justify.center);
    flexpanel_node_style_set_align_items(self.node, flexpanel_align.center);
    
    // Prevent clicks from reaching elements below the modal
    self.pointerEvents = true; 
    
    // Settings
    self.backdropColor = props[$ "backdropColor"] ?? global.UI_COL_TEXT_MAIN;
    self.backdropAlpha = props[$ "backdropAlpha"] ?? 0.65;
    self.dismissOnBackdropClick = props[$ "dismissOnBackdropClick"] ?? true;
    self.onClose = props[$ "onClose"] ?? function() {};
    
    // Draw Backdrop
    self.onDraw = method(self, function() {
        draw_set_alpha(self.backdropAlpha);
        draw_set_color(self.backdropColor);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        draw_set_alpha(1.0);
    });
    
    // Handle backdrop click
    if (self.dismissOnBackdropClick) {
        self.onMouseDown(method(self, function() {
            if (global.UI.deepestTarget == self) {
                self.close();
            }
        }));
    }
    
    // ── Content Panel ────────────────────────────────────────────────────────
    var _panelStyle = props[$ "panelStyle"] ?? {};
    var _panelProps = props[$ "panelProps"] ?? {};
    
    if (_panelStyle[$ "width"] == undefined) _panelStyle.width = 440;
    if (_panelStyle[$ "flexDirection"] == undefined) _panelStyle.flexDirection = "column";
    if (_panelProps[$ "backgroundColor"] == undefined) _panelProps.backgroundColor = global.UI_COL_BG_CARD;
    if (_panelProps[$ "borderRadius"] == undefined) _panelProps.borderRadius = 12;
    
    self.Panel = new UiNode(_panelStyle, _panelProps);
    self.Panel.pointerEvents = true;
    self.Panel.onMouseDown(function() {}); // Block clicks from propagating to the backdrop
    
    if (self.Panel.borderWidth == undefined) {
        self.Panel.borderWidth = 1;
        self.Panel.borderColor = global.UI_COL_BORDER;
        self.Panel.border = true;
    }
    
    // Draw Drop Shadow for the Panel
    self.Panel.onDraw = method(self.Panel, function() {
        var _radius = self.borderRadius;
        // Soft drop shadow
        draw_set_alpha(0.15);
        draw_set_color(c_black);
        draw_roundrect_ext(self.x1 - 2, self.y1 - 2, self.x2 + 2, self.y2 + 8, _radius + 2, _radius + 2, false);
        draw_set_alpha(0.05);
        draw_roundrect_ext(self.x1 - 6, self.y1 - 4, self.x2 + 6, self.y2 + 16, _radius + 6, _radius + 6, false);
        draw_set_alpha(1.0);
        
        // Background
        draw_set_color(self.backgroundColor);
        draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, _radius, _radius, false);
        
        // Border
        if (self.border) {
            draw_set_color(self.borderColor);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, _radius, _radius, true);
        }
    });
    
    // We keep base add to add the Panel to the modal root
    self.add_base = self.add;
    self.add_base(self.Panel);
    
    // ── Header ───────────────────────────────────────────────────────────────
    self.title = props[$ "title"] ?? undefined;
    self.showCloseButton = props[$ "showCloseButton"] ?? true;
    
    if (self.title != undefined || self.showCloseButton) {
        self.Header = new UiNode({
            width: "100%",
            flexDirection: "row",
            justifyContent: self.title != undefined ? "space-between" : "flex-end",
            alignItems: "center",
            padding: 16
        });
        
        self.Header.onDraw = method(self.Header, function() {
            draw_set_color(global.UI_COL_BORDER);
            draw_line(self.x1, self.y2 - 1, self.x2, self.y2 - 1);
        });
        
        self.Panel.add(self.Header);
        
        if (self.title != undefined) {
            self.Header.add(new UiText(self.title, {}, { color: global.UI_COL_TEXT_MAIN, font: fText }));
        }
        
        if (self.showCloseButton) {
            var _closeBtn = new UiButton("×", { width: 28, height: 28 }, { variant: "ghost" });
            _closeBtn.onClick(method(self, function() {
                self.close();
            }));
            self.Header.add(_closeBtn);
        }
    }
    
    // ── Body ─────────────────────────────────────────────────────────────────
    self.Body = new UiNode({
        width: "100%",
        padding: 16,
        flexDirection: "column"
    });
    self.Panel.add(self.Body);
    
    // Override add to insert components into the Body
    self.add = function(child) {
        self.Body.add(child);
        return self;
    }
    
    // ── Methods ──────────────────────────────────────────────────────────────
    self.open = function() {
        if (self.parent == undefined) {
            global.UI.getOverlay().add(self);
        }
    }
    
    self.close = function() {
        self.onClose();
        self.destroy();
    }
}
