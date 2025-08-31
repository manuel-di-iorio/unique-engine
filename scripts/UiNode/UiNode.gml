function UiNode(style = {}, props = {}) constructor {
    self.root = props[$ "root"] ?? false;
    self.id = global.UI_ID++; 
    style.data = self;
    self.node = flexpanel_create_node(style);
    self.onMount = undefined;
    self.onDraw = undefined;
    self.onDestroy = undefined;
    self.pointerEvents = props[$ "pointerEvents"] ?? false;
    self.border = props[$ "border"] ?? false;
    self.visible = props[$ "visible"] ?? true;
    self.children = [];
    self.childrenLength = 0;
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
    self.width = 0;
    self.height = 0;
    self.hovered = false;
    self.parent = undefined;
    self.eventListeners = {};
    self.scrollTop = 0;
    self.surface = undefined;
    self.isScrollbar = props[$ "isScrollbar"] ?? false;
    self.mounted = false;
    self.scrollableParent = undefined;
    self.display = style[$ "display"] != "none";
    self.handpoint = props[$ "handpoint"] ?? false;
    self.hasStepEvent = false;
    self.__UiScrollbar = undefined;
    self.__scrollBoundsCachedScrollTop = undefined;
    self.__scrollBoundsCachedResult = undefined;
    self.destroyed = false;
    self.drawIndex = 0;
    
    // Root-only props
    if (self.root) {  
        self.deepestTarget = undefined;
        self.previousTarget = undefined;
        self.needsUpdate = true;
        self.needsRedraw = true;
        self.surface = undefined;
        self.mouseX = undefined;
        self.mouseY = undefined;
        self.mouseXPrev = undefined;
        self.mouseYPrev = undefined;
        self.stepHandlers = [];
        self.layoutUpdated = undefined;
        self.grid = ds_grid_create(0, 0);
        self.gridW = 0;
        self.gridH = 0;
        self.gridSize = 64;
        self.hoveredElements = [];
    }
    
    // Set the size of the node
    function setSize(w, h) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, w, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, h, flexpanel_unit.point);
        global.UI.needsUpdate = true;
        
        if (self.root) {
            self.gridW = ceil(w / self.gridSize);
            self.gridH = ceil(h / self.gridSize);
            ds_grid_resize(self.grid, self.gridW, self.gridH);
            ds_grid_clear(self.grid, undefined);
        }
        
        return self;
    }
    
    // Add one or more children to this node
    // @param ...objects
    function add() {
        gml_pragma("forceinline");
        for (var i=0; i<argument_count; i++) {
            var elem = argument[i];
            
            // Remove the element from its previous parent
            if (elem.parent != undefined) elem.parent.remove(elem);
            
            flexpanel_node_insert_child(self.node, elem.node, self.childrenLength);
            array_push(self.children, elem);
            self.childrenLength++;
            elem.parent = self;
        }
        global.UI.needsUpdate = true;
        
        return self;
    }
    
    // Remove a child
    function remove(child) {
        gml_pragma("forceinline");
        global.UI.needsUpdate = true; 
        child.parent = undefined;
        flexpanel_node_remove_child(self.node, child.node);
        
        for (var i = self.childrenLength - 1; i >= 0; i--) {
            if (self.children[i] == child) {
                array_delete(self.children, i, 1);
                self.childrenLength--;
                break;
            }
        }
        
        
        return self;
    }
    
    // Remove all children from the node tree (not from the memory, use destroy() for that)
    function clear() {
        gml_pragma("forceinline");
        flexpanel_node_remove_all_children(self.node);
        global.UI.needsUpdate = true;
        self.children = [];
        self.childrenLength = 0;
        return self;
    }
    
    // Remove (if exists) the step handlers of this element
    function __removeStepHandler() {
        if (!self.hasStepEvent) return;
        self.hasStepEvent = false;
        
        var stepHandlers = global.UI.stepHandlers;
        for (var i = array_length(stepHandlers) - 1; i >= 0; i--) {
            var stepHandler = stepHandlers[i];
            if (stepHandler[1] == self) {
                array_delete(stepHandlers, i, 1);
            }   
        }
    }
    
    // Delete this node and optionally also its children from memory
    function destroy() {
        gml_pragma("forceinline");
        global.UI.needsUpdate = true;
        
        for (var i = self.childrenLength - 1; i >= 0; i--) {
            self.children[i].destroy();
        }
        
        self.parent.remove(self);
        flexpanel_delete_node(self.node, false);
        self.children = [];
        self.childrenLength = 0;
        self.destroyed = true;
        self.__removeStepHandler();
        
        return self; 
    }
    
    // Delete the node's children from memory but not the node itself
    function destroyChildren() {
        gml_pragma("forceinline");
        
        for (var i = self.childrenLength - 1; i >= 0; i--) {
            var elem = self.children[i];
            elem.destroyChildren();
            
            var elemOnDestroy = elem[$ "onDestroy"];
            if (elemOnDestroy != undefined) elemOnDestroy(); 
         
            elem.children = [];
            elem.childrenLength = 0;
            elem.__removeStepHandler();
            elem.destroyed = true;
            flexpanel_delete_node(elem.node, false);
        }
        
        flexpanel_node_remove_all_children(self.node);
        self.__UiScrollbar = undefined;
         
        global.UI.needsUpdate = true;
        self.children = [];
        self.childrenLength = 0;
        return self; 
    }
    
    // Count the children
    function count() {
        gml_pragma("forceinline");
        return self.childrenLength;
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
        for (var i = 0; i < self.childrenLength; i++) {
            var _child = self.children[i];
            cb(_child);
            
            if (recursive) {
                _child.traverseChildren(cb, recursive);
            }
        }
        return self;
    }
    
    function reduceChildren(cb, acc, recursive = true) {
        gml_pragma("forceinline");

        for (var i = 0; i < self.childrenLength; i++) {
            var _child = self.children[i];
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
    
    // Scrolling bound check    
    function __isInScrollBounds() {
        gml_pragma("forceinline");
        var _scrollableParent = self.scrollableParent;

        if (self.isScrollbar || _scrollableParent == undefined) return true;
        
        if (self.__scrollBoundsCachedScrollTop == self.scrollTop && !global.UI.layoutUpdated) {
            return self.__scrollBoundsCachedValue;
        }
        
        self.__scrollBoundsCachedScrollTop = _scrollableParent.scrollTop;
    
        // Relative start position
        var elemLayout = self.layout;
        var elemTop = elemLayout.top - elemLayout.paddingTop;
        var elemBottom = elemTop + elemLayout.height + elemLayout.paddingBottom;
    
        var parentLayout = _scrollableParent.layout;

        // Calculate the visible area based on the scroll
        var visibleTop = parentLayout.top + _scrollableParent.scrollTop;
        var visibleBottom = visibleTop + parentLayout.height;

        // If fully outside then it is invisible
        if (elemBottom < visibleTop || elemTop > visibleBottom) {
            self.__scrollBoundsCachedValue = false;
            return false;
        }
    
        self.__scrollBoundsCachedValue = true;
        return true;
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
    
    function setWidth(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    } 
    
    function getWidth() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_width(self.node).value;
    }
    
    function setHeight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_height(self.node, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
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
    
    function getLeft() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.left).value;
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
    
    function setRight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.right, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function getRight() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.right).value;
    }
    
    function setBottom(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.bottom, value, flexpanel_unit.point);
        global.UI.needsUpdate = true;
    }
    
    function getBottom() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.bottom).value;
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
    
    // Scrollbar
    function enableScrollbar(thumbColor = undefined) {
        gml_pragma("forceinline");
        self.__UiScrollbar = new UiScrollbar({
            position: "absolute",
            top: 0,
            right: 0,
            bottom: 0,
            width: 11
        }, { isScrollbar: true, thumbColor });
        self.add(self.__UiScrollbar);
    }
    
    function disableScrollbar() {
        gml_pragma("forceinline");
        self.__UiScrollbar.destroy();
        self.__UiScrollbar = undefined;
    }
    
    // Events
    function onStep(cb) {
        var _this = self;
        self.hasStepEvent = true;
        array_push(global.UI.stepHandlers, [ cb, _this ]);
    }
    
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
    
    function __updateLayout() {
        gml_pragma("forceinline");
        
        // Cache the nearest scrollable parent (if exists)
        if (!self.isScrollbar) {
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
        
        self.layout = flexpanel_node_layout_get_position(self.node, false);
        self.width = layout.width;
        self.height = layout.height;
        self.x1 = layout.left; 
        self.y1 = layout.top - (self.scrollableParent ? self.scrollableParent.scrollTop : 0);
        self.x2 = layout.left + self.width; 
        self.y2 = self.y1 + self.height;
        self.xp1 = self.x1 - layout.paddingLeft;
        self.yp1 = self.y1 - layout.paddingTop;
        self.xp2 = self.x2 + layout.paddingRight;
        self.yp2 = self.y2 + layout.paddingBottom;
        
        self.__addToGrid();
        
        // Run the onMount method
        if (!self.mounted) {
            self.mounted = true;
            if (self.onMount != undefined) self.onMount();
        }
        
        var _children = self.children;
        for (var i = self.childrenLength - 1; i >= 0; i--) {
            _children[i].__updateLayout();
        }
    }
    
   function __getNearestGridElements() {
        gml_pragma("forceinline");
        var ui = global.UI;
        if (ui.gridW == 0 || ui.gridH == 0) return [];
        
        // Calculate expanded area around mouse
        var margin = 16;
        var mouseX1 = mouseX - margin;
        var mouseY1 = mouseY - margin;
        var mouseX2 = mouseX + margin;
        var mouseY2 = mouseY + margin;
        
        // Convert to grid coordinates
        var gridX1 = max(0, ~~(mouseX1 / ui.gridSize));
        var gridY1 = max(0, ~~(mouseY1 / ui.gridSize));
        var gridX2 = min(ui.gridW - 1, ~~(mouseX2 / ui.gridSize));
        var gridY2 = min(ui.gridH - 1, ~~(mouseY2 / ui.gridSize));
        
        var candidates = [];
        var processedIds = {};
        
        // Collect all nodes in the area
        for (var gx = gridX1; gx <= gridX2; gx++) {
            for (var gy = gridY1; gy <= gridY2; gy++) {
                var cell = ds_grid_get(ui.grid, gx, gy);
                if (!is_array(cell)) continue;
                
                for (var i = 0, l = array_length(cell); i < l; i++) {
                    var elem = cell[i];
                    
                    // Avoid duplicates
                    if (!processedIds[$ elem.id] && elem.pointerEvents && elem.isVisible()) {
                        processedIds[$ elem.id] = true;
                        array_push(candidates, elem);
                    }
                }
            }
        }
        
        // Sort candidates by drawIndex (higher drawIndex = drawn later = on top)
        array_sort(candidates, function(a, b) {
            if (a.drawIndex < b.drawIndex) return -1;
            if (a.drawIndex > b.drawIndex) return 1;
            return 0;
        });
        
        return candidates;
    }
    
    // Calculate the layout of this node and its children
    function update() {
        gml_pragma("forceinline"); 
        self.layoutUpdated = false;
        
        if (self.needsUpdate) {
            self.needsUpdate = false;
            self.layoutUpdated = true;
            flexpanel_calculate_layout(self.node, undefined, undefined, flexpanel_direction.LTR);
            
            // Clear the spatial grid
            ds_grid_clear(self.grid, undefined);
            
            // Update the elements position when the layout changes
            self.__updateLayout();
        }
        
        // Cache mouse vars
        self.mouseX = device_mouse_x_to_gui(0);
        self.mouseY = device_mouse_y_to_gui(0);
        self.mouseChanged = self.mouseX != self.mouseXPrev || self.mouseY != self.mouseYPrev;
        self.mouseLeftReleased = mouse_check_button_released(mb_left);
        
        // Check the hover/unhover events
        var _currentlyHovered = self.deepestTarget;
        if (self.mouseChanged) {
            self.deepestTarget = undefined;
        
            var _nearestElems = self.__getNearestGridElements();
        
            for (var i = array_length(_nearestElems) - 1; i >= 0; i--) {
                var _elem = _nearestElems[i];   
                
                if (self.deepestTarget == undefined && point_in_rectangle(self.mouseX, self.mouseY, _elem.xp1, _elem.yp1, _elem.xp2, _elem.yp2)) {
                    _elem.hovered = true;
                    self.dispatchEvent(UI_EVENT.mouseenter, _elem); 
                    self.dispatchEvent(UI_EVENT.mouseover, _elem);
                    self.deepestTarget = _elem;
                    
                    if (_elem.handpoint && window_get_cursor() == cr_default) {
                        window_set_cursor(cr_handpoint);
                    }
                    
                    break;
                }
            }

            // Unhover the previous element
            if (_currentlyHovered != undefined && _currentlyHovered != self.deepestTarget) {
                window_set_cursor(cr_default);
                _currentlyHovered.hovered = false;
                self.dispatchEvent(UI_EVENT.mouseleave, _currentlyHovered); 
                self.dispatchEvent(UI_EVENT.mouseout, _currentlyHovered);
                self.previousTarget = undefined;
            }
            
            self.previousTarget = self.deepestTarget;
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
                    global.UI.dispatchEvent(UI_EVENT.click, deepestTarget);
                }
                
                global.UI_CLICK_START = undefined;
            }
        }
        
        // Run the step handlers
        for (var i = array_length(self.stepHandlers) - 1; i >= 0; i--) {
            self.stepHandlers[i][0](self.layoutUpdated);
        }
        
        self.mouseXPrev = self.mouseX;
        self.mouseYPrev = self.mouseY;
    }
    
    function renderChild(debug = false) {
        gml_pragma("forceinline");
        if (!self.isVisible() || !self.mounted) return;

        var ui = global.UI;
        
        self.drawIndex = ui.rootDrawIndex++;
        var _scissor = undefined;

        // Draw the border if enabled
        if (self.border) {
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
        }
        
        if (self.__UiScrollbar != undefined) {
            _scissor = gpu_get_scissor();
            gpu_set_scissor(self.xp1, self.yp1, self.xp2 - self.xp1, self.yp2 - self.yp1);
        }
        
        // Run the draw method of the element
        if (self.onDraw != undefined) self.onDraw();
        
        // Render the children
        for (var i = 0; i < self.childrenLength; i++) {
            var child = self.children[i];
            if (child.isScrollbar) continue;
            child.renderChild(debug);
        }
        
        // Reset the previous scissor and render the scrollbar
        if (self.__UiScrollbar != undefined && _scissor != undefined) {
            gpu_set_scissor(_scissor);
            self.__UiScrollbar.renderChild(debug);
            self.__UiScrollbar.Thumb.drawIndex = ui.rootDrawIndex++;
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
    
    // Render the node and its children to the static surface
    // Pass `true` as first argument to draw the nodes bounds and their (optional) name.
    function render(debug = false) {
        self.rootDrawIndex = 0;
        
        gml_pragma("forceinline");
        if (self.width) {
            if (!surface_exists(self.surface)) {
                self.surface = surface_create(self.width, self.height);
                self.needsRedraw = true;
            }
            
            if (self.layoutUpdated || self.needsRedraw) {
                self.needsRedraw = false;
                var currentBlendMode = gpu_get_blendmode_ext_sepalpha();
                gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_inv_dest_alpha, bm_one);
                surface_set_target(self.surface);
                draw_clear_alpha(c_black, 0);
                self.renderChild(debug);
                surface_reset_target();
    			gpu_set_blendmode_ext_sepalpha(currentBlendMode);
            }
            
            draw_surface(self.surface, 0, 0);
        }
    }
    
    // Spatial partition grid methods
    function __addToGrid() {
        var ui = global.UI;
        if (ui.gridW == 0 || ui.gridH == 0) return;
        
        // Calculate grid bounds for this node
        var gridX1 = max(0, floor(self.xp1 / ui.gridSize));
        var gridY1 = max(0, floor(self.yp1 / ui.gridSize));
        var gridX2 = min(ui.gridW - 1, floor(self.xp2 / ui.gridSize));
        var gridY2 = min(ui.gridH - 1, floor(self.yp2 / ui.gridSize));
        
        // Store cells this node occupies
        for (var gx = gridX1; gx <= gridX2; gx++) {
            for (var gy = gridY1; gy <= gridY2; gy++) {
                
                var cells = ds_grid_get(ui.grid, gx, gy);
                if (cells == undefined) {
                    cells = [];
                    ds_grid_set(ui.grid, gx, gy, cells);
                }
                array_push(cells, self);
            }
        }
    }
     
    setName(style[$ "name"] ?? "UiNode");
}