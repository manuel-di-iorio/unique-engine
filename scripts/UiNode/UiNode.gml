function UiNode(style = {}, props = {}) constructor {
    self.id = global.UI_ID++; 
    style.data = self;
    self.node = flexpanel_create_node(style);
    self.onMount = undefined;
    self.onStep = undefined;
    self.onDraw = undefined;
    self.pointerEvents = props[$ "pointerEvents"] ?? false;
    self.border = props[$ "border"] ?? false;
    self.visible = props[$ "visible"] ?? true;
    self.layout = {
        left: 0, top: 0, right: 0, bottom: 0, width: 0, height: 0,
        marginLeft: 0, marginTop: 0, marginRight: 0, marginBottom: 0,
        paddingLeft: 0, paddingTop: 0, paddingRight: 0, paddingBottom: 0,
    };
    self.x1 = 0;
    self.y1 = 0;
    self.x2 = 0;
    self.y2 = 0;
    self.xp1 = 0;
    self.yp1 = 0;
    self.xp2 = 0;
    self.yp2 = 0;
    self.hovered = false;
    self.needsUpdate = true;
    self.parent = undefined;
    self.eventListeners = {};
    self.__UiScrollbar = undefined;
    self.scrollTop = 0;
    self.surface = undefined;
    self.__scrollBoundsResult = undefined;
    self.isScrollbar = props[$ "isScrollbar"] ?? false;
    self.mounted = false;
    self.scrollableParent = undefined;
    
    function getMouseX() {
        return device_mouse_x_to_gui(0);
    }
    
    function getMouseY() {
        return device_mouse_y_to_gui(0);
    }
    
    // Get the mouse Y coordinate, based on scrolling of the parents
    function getMouseYByScroll() {
        var totalScrollTop = 0;
        var currentNode = self.parent;
        
        while (currentNode != undefined) {
            totalScrollTop += currentNode.scrollTop;
            currentNode = currentNode.parent;
        }
        
        return device_mouse_y_to_gui(0) + totalScrollTop;
    }
    
    // Set the size of the node
    function setSize(winW, winH) {
        flexpanel_node_style_set_width(self.node, winW, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, winH, flexpanel_unit.point);
        global.UI.needsUpdate = true;
        return self;
    }
    
    // Add one or more children to this node
    // @param ...objects
    function add() {
        for (var i=0; i<argument_count; i++) {
            var elem = argument[i];
            
            // Remove the element from its previous parent
            // @todo: flexpanel may do this operation automatically, need to test it.
            if (elem.parent != undefined) {
                flexpanel_node_remove_child(elem.parent, elem.node);
            }
            
            flexpanel_node_insert_child(self.node, elem.node, flexpanel_node_get_num_children(self.node));
            elem.parent = self;
        }
        global.UI.needsUpdate = true;
        
        return self;
    }
    
    // Remove a child
    function remove(child) {
        child.parent = undefined;
        flexpanel_node_remove_child(node, child.node);
        global.UI.needsUpdate = true;
        return self;
    }
    
    // Remove all children
    function clear() {
        flexpanel_node_remove_all_children(node);
        global.UI.needsUpdate = true;
        return self;
    }
    
    // Count the children
    function count() {
        return flexpanel_node_get_num_children(node);
    }
    
    // Run a callback on the node itself and its children
    function traverse(cb, recursive = true) {
        cb(self);
        traverseChildren(cb, recursive);
        return self;
    }
    
    // Run a callback on the children
    function traverseChildren(cb, recursive = true) {
        for (var i = 0, l = flexpanel_node_get_num_children(self.node); i < l; i++) {
            var _child = flexpanel_node_get_data(flexpanel_node_get_child(self.node, i));
            cb(_child);
            
            if (recursive) {
                _child.traverseChildren(cb, recursive);
            }
        }
        return self;
    }
    
    function reduceChildren(cb, acc, recursive = true) {
        for (var i = 0, l = flexpanel_node_get_num_children(self.node); i < l; i++) {
            var _child = flexpanel_node_get_data(flexpanel_node_get_child(self.node, i));
            acc = cb(acc, _child, i);
            
            if (recursive) {
                acc = _child.reduceChildren(cb, acc, true);
            }
        }
        
        return acc;
    }
    
    function show() {
        flexpanel_node_style_set_display(self.node, flexpanel_display.flex);
        global.UI.needsUpdate = true;
    }
    
    function hide() {
        flexpanel_node_style_set_display(self.node, flexpanel_display.none);
        global.UI.needsUpdate = true;
    }
    
    function isVisible() {
        return flexpanel_node_style_get_display(self.node) == flexpanel_display.flex && self.visible && self.__isInScrollBounds();
    }
    
    function setName(name) {
        flexpanel_node_set_name(self.node, name); 
        return self;
    }
    
    function getName() {
        return flexpanel_node_get_name(self.node);
    }
    
    function getWidth() {
        return flexpanel_node_style_get_width(self.node).value;
    }
    
    function getHeight() {
        return flexpanel_node_style_get_height(self.node).value;
    }
    
    function setLeft(value) {
        flexpanel_node_style_set_position(self.node, flexpanel_edge.left, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setTop(value) {
        flexpanel_node_style_set_position(self.node, flexpanel_edge.top, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function getTop() {
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.top).value;
    }
    
    function setMarginTop(value) {
        flexpanel_node_style_set_margin(self.node, flexpanel_edge.top, value);
        global.UI.needsUpdate = true;
    }
    
    function getMarginTop() {
        return flexpanel_node_style_get_margin(self.node, flexpanel_edge.top).value;
    }
    
    function setRight(value) {
        flexpanel_node_style_set_position(self.node, flexpanel_edge.right, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setBottom(value) {
        flexpanel_node_style_set_position(self.node, flexpanel_edge.bottom, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setWidth(value) {
        flexpanel_node_style_set_width(self.node, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setHeight(value) {
        flexpanel_node_style_set_height(self.node, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    // Scrollbar
    function enableScrollbar() {
        self.__UiScrollbar = new UiScrollbar({
            position: "absolute",
            top: 0,
            right: 5,
            bottom: 0,
            width: 6
        }, { isScrollbar: true });
        self.add(self.__UiScrollbar);
    }
    
    function disableScrollbar() {
        self.remove(self.__UiScrollbar);
        self.__UiScrollbar = undefined;
    }
    
    // Events
    function onClick(cb) {
        self.addEventListener(UI_EVENT.click, cb);
        return self;
    }
    
    function onMouseDown(cb) {
        self.addEventListener(UI_EVENT.mousedown, cb);
        return self;
    }
    
    function onMouseUp(cb) {
        self.addEventListener(UI_EVENT.mouseup, cb);
        return self;
    }
    
    function onWheelUp(cb) {
        self.addEventListener(UI_EVENT.wheelup, cb); 
        return self;
    }
    
    function onWheelDown(cb) {
        self.addEventListener(UI_EVENT.wheeldown, cb); 
        return self;
    }
    
    function addEventListener(eventType, callback, useCapture = false) {
        if (self.eventListeners[$ eventType] == undefined) {
            self.eventListeners[$ eventType] = { capture: [], bubble: [] };
        }
        
        var phase = useCapture ? "capture" : "bubble";
        array_push(self.eventListeners[$ eventType][$ phase], callback);
        
        return self;
    }
    
    function removeEventListener(eventType, callback, useCapture = false) {
        if (self.eventListeners[$ eventType] == undefined) return;
        
        var phase = useCapture ? "capture" : "bubble";
        var listeners = self.eventListeners[$ eventType][$ phase];
        
        for (var i = array_length(listeners) - 1; i >= 0; i--) {
            if (listeners[i] == callback) {
                array_delete(listeners, i, 1);
                break;
            }
        }
        
        return self;
    }
    
    function clearEventListeners(eventType) {
        delete self.eventListeners[$ eventType];
        return self;
    }
    
    function dispatchEvent(event) {
        // Build path from root to target
        var path = [];
        var current = event.target;
        while (current != undefined) {
            array_insert(path, 0, current); // Insert at beginning
            current = current.parent;
        }
        
        // CAPTURE PHASE - from root to target (excluding target)
        event.phase = "capture";
        for (var i = 0; i < array_length(path) - 1 && !event.stopped; i++) {
            current = path[i];
            event.currentTarget = current;
            
            if (current.eventListeners[$ event.type] != undefined) {
                var captureListeners = current.eventListeners[$ event.type].capture;
                for (var j = 0; j < array_length(captureListeners) && !event.stopped; j++) {
                    captureListeners[j](event);
                }
            }
        }
        
        // TARGET PHASE - on the target itself
        if (!event.stopped) {
            event.phase = "target";
            event.currentTarget = event.target;
            
            if (event.target.eventListeners[$ event.type] != undefined) {
                // Execute both capture and bubble listeners on target
                var targetListeners = event.target.eventListeners[$ event.type];
                
                for (var j = 0, jl = array_length(targetListeners.capture); j < jl && !event.stopped; j++) {
                    targetListeners.capture[j](event);
                }
                
                for (var j = 0, jl = array_length(targetListeners.bubble); j < jl && !event.stopped; j++) {
                    targetListeners.bubble[j](event);
                }
            }
        }
        
        // BUBBLE PHASE - from target parent to root
        if (!event.stopped && event.type != UI_EVENT.mouseenter && event.type != UI_EVENT.mouseleave) {
            event.phase = "bubble";
            for (var i = array_length(path) - 2; i >= 0 && !event.stopped; i--) {
                current = path[i];
                event.currentTarget = current;
                
                if (current.eventListeners[$ event.type] != undefined) {
                    var bubbleListeners = current.eventListeners[$ event.type].bubble;
                    for (var j = 0, jl = array_length(bubbleListeners); j < jl && !event.stopped; j++) {
                        bubbleListeners[j](event);
                    }
                }
            }
        }
        
        return self;
    }
    
    // @todo recursive mode
    function focus(recursive = false, parentLimit = undefined) {
        if (parent != undefined) {
            flexpanel_node_remove_child(parent.node, self.node);
            flexpanel_node_insert_child(parent.node, self.node, flexpanel_node_get_num_children(parent.node));
        }
    
        global.UI.needsUpdate = true;
    }
    
    
    function __isInScrollBounds() {
        if (self.isScrollbar) return true;
        
        // Relative start position
        var elemLayout = self.layout;
        var elemTop = elemLayout.top - elemLayout.paddingTop;
        var elemBottom = elemTop + elemLayout.height + elemLayout.paddingBottom;
    
        var scrollableParent = self.scrollableParent;
        if (scrollableParent == undefined) return true;
        var parentLayout = scrollableParent.layout;

        // Calculate the visible area based on the scroll
        var visibleTop = parentLayout.top + scrollableParent.scrollTop;
        var visibleBottom = visibleTop + parentLayout.height;

        // If fully outside then it is invisible
        if (elemBottom < visibleTop || elemTop > visibleBottom) {
            return false;
        }
    
        return true;
    }
    
    function __updateLayout() {
        self.layout = flexpanel_node_layout_get_position(self.node, false);
        self.x1 = self.layout.left; 
        self.y1 = self.layout.top; 
        self.x2 = self.layout.left + self.layout.width; 
        self.y2 = self.layout.top + self.layout.height;
        self.xp1 = self.x1 - self.layout.paddingLeft;
        self.yp1 = self.y1 - self.layout.paddingTop;
        self.xp2 = self.x2 + self.layout.paddingRight;
        self.yp2 = self.y2 + self.layout.paddingBottom;
        
        // Cache the nearest scrollable parent (if exists)
        if (self.isScrollbar) return;
        
        var currentParent = self.parent;
    
        while (currentParent != undefined) {
            if (currentParent.isScrollbar) {
                currentParent = currentParent.parent;
                continue;
            }
            
            if (currentParent.__UiScrollbar != undefined) {
                self.scrollableParent = currentParent;
                break;
            }
        
            currentParent = currentParent.parent;
        }
    }
    
    function checkEvents(updated) {
        // Cache the position
        if (!self.mounted || updated) {
            self.__updateLayout();
        }
        
        if (!self.mounted) {
            self.mounted = true;
            if (self.onMount != undefined) self.onMount();
        }
        
        self.__scrollBoundsResult = undefined;
        if (!self.isVisible()) return undefined;
        
        // Process children first
        var deepestTarget = undefined;
        
        for (var i = flexpanel_node_get_num_children(self.node) - 1; i >= 0; i--) {
            var child = flexpanel_node_get_data(flexpanel_node_get_child(self.node, i));
            
            var childDeepest = child.checkEvents(updated);
            if (childDeepest != undefined && deepestTarget == undefined) {
                deepestTarget = childDeepest;
            }
        }
        
        // Check hover state
        if (self.pointerEvents) {
            var mx = self.getMouseX();
            var my = self.parent == undefined || !self.parent.isScrollbar ? self.getMouseYByScroll() : self.getMouseY();
            var currentlyHovered = point_in_rectangle(mx, my, self.xp1, self.yp1, self.xp2, self.yp2);
    
            if (currentlyHovered && deepestTarget == undefined) {
                deepestTarget = self;
            }
            
            // Mouse hover events
            //if (currentlyHovered != self.hovered) {
                //if (currentlyHovered) {
                    //// Mouse entered
                    //global.UI.dispatchEvent(new UiEvent(UI_EVENT.mouseenter, self));
                    //
                    //global.UI.dispatchEvent(new UiEvent(UI_EVENT.mouseover, self));
                //} else {
                    //// Mouse left
                    //global.UI.dispatchEvent(new UiEvent(UI_EVENT.mouseleave, self));
                    //
                    //global.UI.dispatchEvent(new UiEvent(UI_EVENT.mouseout, self));
                //}
            //}
            
            if (mouse_check_button_released(mb_left)) {
                global.UI.dispatchEvent(new UiEvent(UI_EVENT.mouseup, self));
            }
            
            self.hovered = false;
        }
        
        // Run the step method of the current element
        if (self.onStep != undefined) self.onStep();
        
        return deepestTarget;
    }
    
    // Calculate the layout of this node and its children
    function update() {
        var _updated = false;
        if (self.needsUpdate) {
            self.needsUpdate = false;
            _updated = true;
            flexpanel_calculate_layout(self.node, undefined, undefined, flexpanel_direction.LTR);
        }
        
        var deepestTarget = self.checkEvents(_updated);
        
        // Click event handled only on root
        if (deepestTarget != undefined) {
            deepestTarget.hovered = true;

            // Mouse move event
            // @todo expensive to always dispatch this event on a hovered element
            //global.UI.dispatchEvent(new UiEvent(UI_EVENT.mousemove, deepestTarget));
            
            // Wheel events
            if (mouse_wheel_up()) {
                global.UI.dispatchEvent(new UiEvent(UI_EVENT.wheelup, deepestTarget));
            }
            if (mouse_wheel_down()) {
                global.UI.dispatchEvent(new UiEvent(UI_EVENT.wheeldown, deepestTarget));
            }
            
            if (mouse_check_button_pressed(mb_left)) {
                global.UI_CLICK_START = deepestTarget;
                global.UI.dispatchEvent(new UiEvent(UI_EVENT.mousedown, deepestTarget));
            }
            
            if (mouse_check_button_released(mb_left)) {
                if (deepestTarget == global.UI_CLICK_START) {
                    call_later(1, time_source_units_frames, method({ deepestTarget }, function() {
                        global.UI.dispatchEvent(new UiEvent(UI_EVENT.click, deepestTarget));
                    }));
                }
                
                global.UI_CLICK_START = undefined;
            }
        }
        
        return self;
    } 
    
    // Render the node and its children, with corrected scroll trasformation if needed
    // Pass `true` as first argument to draw the nodes bounds and their (optional) name.
    function render(debug = false) {
        if (!self.isVisible()) return;
        
        var _matrixPushed = false;
        var _scissor = undefined;

        // Draw the border if enabled
        if (self.border) {
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
        }
        
        if (self.__UiScrollbar != undefined) {
            _scissor = gpu_get_scissor();
            gpu_set_scissor(self.xp1, self.yp1, self.xp2 - self.xp1, self.yp2 - self.yp1);
            
            // Apply scroll transformation if scrollbar exists
            if (self.scrollTop != 0) {
                matrix_set(matrix_world, matrix_build(0, -self.scrollTop, 0, 0, 0, 0, 1, 1, 1));
                _matrixPushed = true;
            }
        }
        
        // Run the draw method of the element
        if (self.onDraw != undefined) self.onDraw();
        
        // Render the children
        for (var i = 0, l = flexpanel_node_get_num_children(self.node); i < l; i++) {
            var child = flexpanel_node_get_data(flexpanel_node_get_child(self.node, i));
            if (child.isScrollbar) continue;
            child.render(debug);
        }
        
        // Reset matrix if we applied scroll transformation
        if (_matrixPushed) {
            matrix_set(matrix_world, matrix_build_identity());
        } 
        
        // Reset the previous scissor and render the scrollbar (without matrix)
        if (self.__UiScrollbar != undefined && _scissor != undefined) {
            gpu_set_scissor(_scissor);
            self.__UiScrollbar.render(debug);
            self.__UiScrollbar.Thumb.onDraw();
        }
        
        // Draw the debug element bounds
        if (debug) {
            draw_set_color(self.hovered ? c_red : c_yellow);
            draw_rectangle(self.xp1, self.yp1, self.xp2, self.yp2, true);
            
            var _name = flexpanel_node_get_name(self.node);
            if (self.hovered && _name != undefined) {
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text(~~mean(self.x1, self.x2), ~~mean(self.y1, self.y2), _name);
            }
        }
    }
    
    setName(style[$ "name"] ?? "UiNode");
}