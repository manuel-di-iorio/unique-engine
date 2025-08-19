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
    self.children = [];
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
    self.deepestTarget = undefined;
    self.needsUpdate = true;
    self.parent = undefined;
    self.eventListeners = {};
    self.__UiScrollbar = undefined;
    self.scrollTop = 0;
    self.surface = undefined;
    self.__scrollBoundsCachedScrollTop = undefined;
    self.__scrollBoundsCachedResult = undefined;
    self.isScrollbar = props[$ "isScrollbar"] ?? false;
    self.mounted = false;
    self.scrollableParent = undefined;
    self.updated = false;
    self.__surface = undefined;
    self.display = true;
    
    // Set the size of the node
    function setSize(winW, winH) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, winW, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, winH, flexpanel_unit.point);
        global.UI.needsUpdate = true;
        return self;
    }
    
    // Add one or more children to this node
    // @param ...objects
    function add() {
        gml_pragma("forceinline");
        for (var i=0; i<argument_count; i++) {
            var elem = argument[i];
            
            // Remove the element from its previous parent
            // @todo: flexpanel may do this operation automatically, need to test it.
            if (elem.parent != undefined) {
                flexpanel_node_remove_child(elem.parent.node, elem.node);
            }
            
            flexpanel_node_insert_child(self.node, elem.node, flexpanel_node_get_num_children(self.node));
            array_push(children, elem);
            elem.parent = self;
        }
        global.UI.needsUpdate = true;
        
        return self;
    }
    
    // Remove a child
    function remove(child) {
        gml_pragma("forceinline");
        child.parent = undefined;
        flexpanel_node_remove_child(node, child.node); 
        global.UI.needsUpdate = true;
        return self;
    }
    
    // Remove all children from the node tree (not from the memory, use destroy() for that)
    function clear() {
        gml_pragma("forceinline");
        flexpanel_node_remove_all_children(self.node);
        global.UI.needsUpdate = true;
        return self;
    }
    
    // Delete this node and optionally also its children from memory
    function destroy(recursive = false) {
        gml_pragma("forceinline");
        flexpanel_delete_node(self.node, true);
        global.UI.needsUpdate = true;
        return self; 
    }
    
    // Delete the node's children from memory but not the node itself
    function destroyChildren() {
        gml_pragma("forceinline");
        
        for (var i = flexpanel_node_get_num_children(self.node) - 1; i >= 0; i--) {
            flexpanel_delete_node(flexpanel_node_get_child(self.node, i), true);
        }
         
        global.UI.needsUpdate = true;
        return self; 
    }
    
    // Count the children
    function count() {
        gml_pragma("forceinline");
        return flexpanel_node_get_num_children(self.node);
    }
    
    // Run a callback on the node itself and its children
    function traverse(cb, recursive = true) {
        gml_pragma("forceinline");
        cb(self);
        traverseChildren(cb, recursive);
        return self;
    }
    
    // Run a callback on the children
    function traverseChildren(cb, recursive = true) {
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
        flexpanel_node_style_set_display(self.node, flexpanel_display.flex);
        self.display = true;
        global.UI.needsUpdate = true;
    }
    
    function hide() {
        gml_pragma("forceinline");
        flexpanel_node_style_set_display(self.node, flexpanel_display.none);
        self.display = false;
        global.UI.needsUpdate = true;
    }
    
    function isVisible() {
        gml_pragma("forceinline");
        return self.display && self.visible && self.__isInScrollBounds();
    }
    
    function setName(name) {
        gml_pragma("forceinline");
        flexpanel_node_set_name(self.node, name); 
        return self;
    }
    
    function getName() {
        return flexpanel_node_get_name(self.node);
    }
    
    function getWidth() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_width(self.node).value;
    }
    
    function getHeight() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_height(self.node).value;
    }
    
    function setLeft(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.left, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setTop(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.top, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function getTop() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.top).value;
    }
    
    function setMarginTop(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_margin(self.node, flexpanel_edge.top, value);
        global.UI.needsUpdate = true;
    }
    
    function getMarginTop() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_margin(self.node, flexpanel_edge.top).value;
    }
    
    function setRight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.right, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setBottom(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.bottom, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setWidth(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function setHeight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_height(self.node, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    // Scrollbar
    function enableScrollbar() {
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
        self.remove(self.__UiScrollbar);
        self.__UiScrollbar.destroy();
        self.__UiScrollbar = undefined;
    }
    
    // Events
    function click() {
        global.UI.dispatchEvent(UI_EVENT.click, self);    
    }
    
    function onClick(cb) {
        gml_pragma("forceinline");
        self.addEventListener(UI_EVENT.click, cb);
        return self;
    }
    
    function onMouseDown(cb) {
        gml_pragma("forceinline");
        self.addEventListener(UI_EVENT.mousedown, cb);
        return self;
    }
    
    function onMouseUp(cb) {
        gml_pragma("forceinline");
        var _this = self;
        self.addEventListener(UI_EVENT.mouseup, cb);
        return self;
    }
    
    function onMouseEnter(cb) {
        gml_pragma("forceinline");
        self.addEventListener(UI_EVENT.mouseenter, cb);
        return self;
    }
    
    function onMouseLeave(cb) {
        gml_pragma("forceinline");
        var _this = self;
        self.addEventListener(UI_EVENT.mouseleave, cb);
        return self;
    }
    
    function onWheelUp(cb) {
        gml_pragma("forceinline");
        self.addEventListener(UI_EVENT.wheelup, cb); 
        return self;
    }
    
    function onWheelDown(cb) {
        gml_pragma("forceinline");
        self.addEventListener(UI_EVENT.wheeldown, cb); 
        return self;
    }
    
    function addEventListener(eventType, callback, useCapture = false) {
        gml_pragma("forceinline");
        if (self.eventListeners[$ eventType] == undefined) {
            self.eventListeners[$ eventType] = { capture: [], bubble: [] };
        }
        
        var phase = useCapture ? "capture" : "bubble";
        array_push(self.eventListeners[$ eventType][$ phase], callback);
        
        return self;
    }
    
    function removeEventListener(eventType, callback, useCapture = false) {
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
        delete self.eventListeners[$ eventType];
        return self;
    }
    
    function dispatchEvent(event, target) {
        gml_pragma("forceinline");
        
        // Build path from root to target
        var path = [];
        var current = target;
        while (current != undefined) {
            array_insert(path, 0, current); // Insert at beginning
            current = current.parent;
        }
        
        // CAPTURE PHASE - from root to target (excluding target)
        var _stopped = false;
        
        for (var i = 0; i < array_length(path) - 1; i++) {
            current = path[i];
            
            if (current.eventListeners[$ event] != undefined) {
                var captureListeners = current.eventListeners[$ event].capture;
                for (var j = 0; j < array_length(captureListeners); j++) {
                    if (captureListeners[j](current)) {
                        _stopped = true;
                        break;
                    }
                }
            }
            
            if (_stopped) break;
        }
        
        // TARGET PHASE - on the target itself
        if (!_stopped) {
            if (target.eventListeners[$ event] != undefined) {
                // Execute both capture and bubble listeners on target
                var targetListeners = target.eventListeners[$ event];
                
                for (var j = 0, jl = array_length(targetListeners.capture); j < jl; j++) {
                    if (targetListeners.capture[j](target)) {
                        _stopped = true;
                        break;
                    }
                }
                
                if (!_stopped) {
                    for (var j = 0, jl = array_length(targetListeners.bubble); j < jl; j++) {
                        if (targetListeners.bubble[j](event)) {
                            _stopped = true;
                            break;
                        }
                    }
                }
            }
        }
        
        // BUBBLE PHASE - from target parent to root
        if (!_stopped && event != UI_EVENT.mouseenter && event != UI_EVENT.mouseleave) {
            for (var i = array_length(path) - 2; i >= 0; i--) {
                current = path[i];
                
                if (current.eventListeners[$ event] != undefined) {
                    var bubbleListeners = current.eventListeners[$ event].bubble;
                    for (var j = 0, jl = array_length(bubbleListeners); j < jl; j++) {
                        if (bubbleListeners[j](current)) {
                            break;
                        }
                    }
                }
            }
        }
        
        return self;
    }
    
    // @todo recursive mode
    function bringOnTop(recursive = false, parentLimit = undefined) {
        gml_pragma("forceinline");
        if (parent != undefined) {
            flexpanel_node_remove_child(parent.node, self.node);
            flexpanel_node_insert_child(parent.node, self.node, flexpanel_node_get_num_children(parent.node));
        }
    
        global.UI.needsUpdate = true;
    }
    
    
    function __isInScrollBounds() {
        gml_pragma("forceinline");
        var scrollableParent = self.scrollableParent;

        if (self.isScrollbar || scrollableParent == undefined) return true;
        
        if (self.__scrollBoundsCachedScrollTop == self.scrollTop && !self.updated) {
            return self.__scrollBoundsCachedValue;
        }
        
        self.__scrollBoundsCachedScrollTop = self.scrollTop;
    
    
        // Relative start position
        var elemLayout = self.layout;
        var elemTop = elemLayout.top - elemLayout.paddingTop;
        var elemBottom = elemTop + elemLayout.height + elemLayout.paddingBottom;
    
        var parentLayout = scrollableParent.layout;

        // Calculate the visible area based on the scroll
        var visibleTop = parentLayout.top + scrollableParent.scrollTop;
        var visibleBottom = visibleTop + parentLayout.height;

        // If fully outside then it is invisible
        if (elemBottom < visibleTop || elemTop > visibleBottom) {
            self.__scrollBoundsCachedValue = false;
            return false;
        }
    
        self.__scrollBoundsCachedValue = true;
        return true;
    }
    
    function __updateLayout() {
        gml_pragma("forceinline");
        self.layout = flexpanel_node_layout_get_position(self.node, false);
        self.width = layout.width;
        self.height = layout.height;
        self.x1 = layout.left; 
        self.y1 = layout.top; 
        self.x2 = layout.left + self.width; 
        self.y2 = layout.top + self.height;
        self.xp1 = self.x1 - layout.paddingLeft;
        self.yp1 = self.y1 - layout.paddingTop;
        self.xp2 = self.x2 + layout.paddingRight;
        self.yp2 = self.y2 + layout.paddingBottom;
        
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
    
    function checkEvents(layoutUpdated, _currentlyHovered) {
        gml_pragma("forceinline");
        var ui = global.UI;
        self.updated = layoutUpdated;
        
        // Cache the position
        if (!mounted || layoutUpdated) {
            self.__updateLayout();
        }
        
        if (!mounted) {
            mounted = true;
            if (self.onMount != undefined) self.onMount();
        }
        
        if (!self.isVisible()) return undefined;
        
        // Process children first
        for (var i = flexpanel_node_get_num_children(self.node) - 1; i >= 0; i--) {
            flexpanel_node_get_data(flexpanel_node_get_child(self.node, i))
                .checkEvents(layoutUpdated, _currentlyHovered);
        }
        
        // Store the mouse relative coords for this element
        self.mouseX = ui.mouseX;
        self.mouseY = self.parent == undefined || !self.parent.isScrollbar ?
            ui.mouseY + (self.scrollableParent != undefined ? self.scrollableParent.scrollTop : 0) 
            : ui.mouseY;
        
        // Check hover state
        if (self.pointerEvents) {
            self.hovered = false;
            
            if (ui.deepestTarget == undefined && point_in_rectangle(self.mouseX, self.mouseY, self.xp1, self.yp1, self.xp2, self.yp2)) {
                self.hovered = true;
                ui.deepestTarget = self;
                ui.dispatchEvent(UI_EVENT.mouseenter, self); 
                ui.dispatchEvent(UI_EVENT.mouseover, self);
           } 
        } 
        
        if (global.UI.mouseLeftReleased) {
            global.UI.dispatchEvent(UI_EVENT.mouseup, self);
        }
        
        if (self.onStep != undefined) self.onStep();
        self.updated = false;
    }
    
    // Calculate the layout of this node and its children
    function update() {
        gml_pragma("forceinline"); 
        var _layoutUpdated = false;
        
        if (self.needsUpdate) {
            self.needsUpdate = false;
            _layoutUpdated = true;
            flexpanel_calculate_layout(self.node, undefined, undefined, flexpanel_direction.LTR);
        }
        
        // Cache mouse vars
        self.mouseX = device_mouse_x_to_gui(0);
        self.mouseY = device_mouse_y_to_gui(0);
        self.mouseLeftReleased = mouse_check_button_released(mb_left);

        var _currentlyHovered = self.deepestTarget;
        self.deepestTarget = undefined;
        self.checkEvents(_layoutUpdated, _currentlyHovered);
        
        if (_currentlyHovered != undefined && _currentlyHovered != self.deepestTarget) {
            self.dispatchEvent(UI_EVENT.mouseleave, _currentlyHovered); 
            self.dispatchEvent(UI_EVENT.mouseout, _currentlyHovered);
        }
        
        // Click event handled only on root
        if (self.deepestTarget != undefined) {
            // Wheel events
            if (mouse_wheel_up()) {
                global.UI.dispatchEvent(UI_EVENT.wheelup, self.deepestTarget);
            }
            if (mouse_wheel_down()) {
                global.UI.dispatchEvent(UI_EVENT.wheeldown, self.deepestTarget);
            }
            
            if (mouse_check_button_pressed(mb_left)) {
                global.UI_CLICK_START = self.deepestTarget;
                global.UI.dispatchEvent(UI_EVENT.mousedown, self.deepestTarget);
            }
            
            if (self.mouseLeftReleased) {
                if (self.deepestTarget == global.UI_CLICK_START) {
                    call_later(1, time_source_units_frames, method({ deepestTarget: self.deepestTarget }, function() {
                        global.UI.dispatchEvent(UI_EVENT.click, deepestTarget);
                    }));
                }
                
                global.UI_CLICK_START = undefined;
            }
        }
    } 
    
    // Render the node and its children, with corrected scroll trasformation if needed
    // Pass `true` as first argument to draw the nodes bounds and their (optional) name.
    function render(debug = false) {
        gml_pragma("forceinline");
        if (!self.isVisible() || !self.mounted) return;
        
        var ui = global.UI;
        
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