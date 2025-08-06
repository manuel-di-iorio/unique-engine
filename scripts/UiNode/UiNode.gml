global.UI = new UiNode({ flexDirection: "row", flexWrap: "wrap" });
global.UI_HOVERED = undefined;

function UiNode(style = {}, props = {}) constructor {
    style.data = self;
    self.node = flexpanel_create_node(style);
    self.draw = function(x1, y1, x2, y2, hovered, _xp1, _yp1, _xp2, _yp2) {};
    self.hoverable = props[$ "hoverable"] ?? true;
    self.border = props[$ "border"] ?? false;
    
    // Set the size of the node
    function setSize(winW, winH) {
        flexpanel_node_style_set_width(self.node, winW, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, winH, flexpanel_unit.point);
        return self;
    }
    
    // Get the absolute or relative layout position data (left, top, width, etc..)
    function getPosition(relative = true) {
        return flexpanel_node_layout_get_position(self.node, relative);
    }
    
    // Add one or more children to this node
    // @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            flexpanel_node_insert_child(self.node, argument[i].node, flexpanel_node_get_num_children(self.node));
        }
        return self;
    }
    
    // Remove a child
    function remove(child) {
        flexpanel_node_remove_child(node, child.node);
        return self;
    }
    
    // Remove all children
    function clear() {
        flexpanel_node_remove_all_children(node);
        return self;
    }
    
    // Count the children
    function count() {
        return flexpanel_node_get_num_children(node);
    }
    
    // Run a callback on the children
    function traverseChildren(cb, recursive = true) {
        for (var i = flexpanel_node_get_num_children(self.node) - 1; i >= 0; i--) {
            var _child = flexpanel_node_get_data(flexpanel_node_get_child(self.node, i));
            cb(_child);
            
            if (recursive) {
                _child.traverseChildren(cb, recursive);
            }
        }
        return self;
    }
    
    // == Root node methods ==
    
    // Calculate the layout of this node and its children
    function update() {
        flexpanel_calculate_layout(self.node, undefined, undefined, flexpanel_direction.LTR);
        global.UI_HOVERED = undefined;
        self.checkHovered();
        return self;
    }
    
    function checkHovered() {
        for (var i = flexpanel_node_get_num_children(self.node) - 1; i >= 0; i--) {
            var _child = flexpanel_node_get_data(flexpanel_node_get_child(self.node, i)); 
            if (_child.checkHovered()) return true;
        }
        
        // Get the element coords
        var _layout = flexpanel_node_layout_get_position(self.node, false);
        var _x1 = _layout.left; 
        var _y1 = _layout.top; 
        var _x2 = _layout.left + _layout.width; 
        var _y2 = _layout.top + _layout.height;
        var _xp1 = _x1 - _layout.paddingLeft;
        var _yp1 = _y1 - _layout.paddingTop;
        var _xp2 = _x2 + _layout.paddingRight;
        var _yp2 = _y2 + _layout.paddingBottom;
        
        // Check if the element is hovered (only if its children are not hovered too)
        var _hovered = self.hoverable && point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _xp1, _yp1, _xp2, _yp2);
        if (_hovered) global.UI_HOVERED = self;
        return _hovered;
    }
    
    // Render the node and its children, from the bottom of the tree to the top
    // (to correctly detect the mouse hover on what's actually on top).
    // - The custom `draw()` event of the node is also called with some layout and hovered props.
    // - Pass `true` as first argument to draw the nodes bounds and their (optional) name.
    function render(debug = false) {
        // Get the element coords
        var _layout = flexpanel_node_layout_get_position(self.node, false);
        var _x1 = _layout.left; 
        var _y1 = _layout.top; 
        var _x2 = _layout.left + _layout.width; 
        var _y2 = _layout.top + _layout.height;
        var _xp1 = _x1 - _layout.paddingLeft;
        var _yp1 = _y1 - _layout.paddingTop;
        var _xp2 = _x2 + _layout.paddingRight;
        var _yp2 = _y2 + _layout.paddingBottom;
        var _hovered = global.UI_HOVERED == self;
        
        // Draw the border if enabled
        if (self.border) {
            draw_set_color(oSceneEditor.uiColBox);
            draw_rectangle(_x1, _y1, _x2, _y2, true);
        }
        
        // Run the draw method of the element
        self.draw(_x1, _y1, _x2, _y2, _hovered, _xp1, _yp1, _xp2, _yp2);
        
        // Render the children
        for (var i = flexpanel_node_get_num_children(self.node) - 1; i >= 0; i--) {
            flexpanel_node_get_data(flexpanel_node_get_child(self.node, i)).render(debug); 
        }
        
        // Draw the debug element bounds
        if (debug && self != global.UI) {
            draw_set_color(#664033);
            //draw_rectangle(_xp1 - _layout.marginLeft, _yp1 - _layout.marginTop, _xp2 + _layout.marginRight, _yp2 + _layout.marginBottom, true); 
            draw_set_color(_hovered ? c_red : c_green);
            draw_rectangle(_xp1, _yp1, _xp2, _yp2, true);
            draw_set_color(c_yellow);
            draw_rectangle(_x1, _y1, _x2, _y2, true);
            
            var _name = flexpanel_node_get_name(self.node);
            if (_name != undefined) {
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text(~~mean(_x1, _x2), ~~mean(_y1, _y2), _name);
            }
        }
    }
}