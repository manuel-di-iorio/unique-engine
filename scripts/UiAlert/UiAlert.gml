/// @desc UiAlert — contextual feedback banner with type, optional title, and dismiss button.
/// Types: "info", "success", "warning", "error"
function UiAlert(message, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiAlert");
    self.alertType    = props[$ "type"]        ?? "info";    // "info","success","warning","error"
    self.alertTitle   = props[$ "title"]       ?? undefined;
    self.message      = message;
    self.dismissible  = props[$ "dismissible"] ?? false;
    self.onDismiss    = props[$ "onDismiss"]   ?? function() {};
    
    // Default width
    if (style[$ "width"] == undefined) self.setWidth("100%");
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.row);
    flexpanel_node_style_set_align_items(self.node, flexpanel_align.flex_start);
    flexpanel_node_style_set_padding(self.node, flexpanel_edge.top,    14);
    flexpanel_node_style_set_padding(self.node, flexpanel_edge.bottom, 14);
    flexpanel_node_style_set_padding(self.node, flexpanel_edge.left,   14);
    flexpanel_node_style_set_padding(self.node, flexpanel_edge.right,  14);
    
    function __alert_palette() {
        switch (self.alertType) {
            case "success": return { bg: #F0FDF4, border: #86EFAC, icon: #16A34A, text: #166534 };
            case "warning": return { bg: #FFFBEB, border: #FCD34D, icon: #D97706, text: #92400E };
            case "error":   return { bg: #FEF2F2, border: #FECACA, icon: #DC2626, text: #991B1B };
            default:        return { bg: #EFF6FF, border: #BFDBFE, icon: #3B82F6, text: #1E40AF };
        }
    }
    
    self.onDraw = method(self, function() {
        var pal = __alert_palette();
        draw_set_color(pal.bg);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        draw_set_color(pal.border);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
        
        // Left accent bar
        draw_set_color(pal.icon);
        draw_rectangle(self.x1, self.y1, self.x1 + 4, self.y2, false);
    });
    
    // Content column
    var _col = new UiNode({ flex: 1, flexDirection: "column", paddingLeft: 10 });
    self.add(_col);
    
    var pal = __alert_palette();
    
    if (self.alertTitle != undefined) {
        _col.add(new UiText(self.alertTitle, { marginBottom: 4, height: 20 }, { color: pal.text }));
    }
    _col.add(new UiText(self.message, { width: "100%" }, { color: pal.text, wrap: true }));
    
    // Dismiss button
    if (self.dismissible) {
        var _dismissBtn = new UiButton("×", { width: 24, height: 24, marginLeft: 8 }, { variant: "ghost" });
        _dismissBtn.onClick(method(self, function() {
            self.hide();
            self.onDismiss();
            global.UI.requestUpdate();
        }));
        self.add(_dismissBtn);
    }
    
    /// @desc Changes the alert type and redraws.
    function setType(_type) {
        self.alertType = _type;
        global.UI.requestRedraw();
    }
    
    /// @desc Changes the alert message.
    function setMessage(_msg) {
        self.message = _msg;
        global.UI.requestUpdate();
    }
}
