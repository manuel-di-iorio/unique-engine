enum UI_EVENT {
    wheelup,
    wheeldown,
    
    mousedown,
    mouseup,
    click,
    doubleclick,
    
    mouseover,
    mouseout,

    // enter/leave do not bubble
    mouseenter,
    mouseleave,
}

global.UI_ID = 0;

function UiNode(style = {}, props = {}) constructor {
    self.id = global.UI_ID++;
    style.name = style[$ "name"] ?? "UiNode";
    style.data = self;
    self.type = "UiNode";
    self.isUiNode = true;
    self.node = flexpanel_create_node(style);
    self.root = false;
    self.parent = undefined;
    self.__drawIndex = 0;
    self.destroyed = false;
    self.onMount = undefined;
    self.onDraw = props[$ "onDraw"] ?? undefined;
    self.onDestroy = props[$ "onDestroy"] ?? undefined;
    self.pointerEvents = props[$ "pointerEvents"] ?? false;
    self.border = props[$ "border"] ?? false;
    self.visible = props[$ "visible"] ?? true;
    self.focusable = props[$ "focusable"] ?? false;
    self.focused = false;
    self.onFocus = props[$ "onFocus"] ?? undefined;
    self.onBlur = props[$ "onBlur"] ?? undefined;
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
    self.eventListeners = {};
    self.scrollTop = 0;
    self.isScrollbar = props[$ "isScrollbar"] ?? false;
    self.mounted = false;
    self.scrollableParent = undefined;
    self.display = style[$ "display"] != "none";
    self.handpoint = props[$ "handpoint"] ?? false;
    self.hasStepEvent = false;
    self.__UiScrollbar = undefined;
    self.__scrollBoundsCachedScrollTop = undefined;
    self.__scrollBoundsCachedResult = undefined;
    self.borderColor = #191A21;

    // Tooltip props
    self.tooltip = props[$ "tooltip"];
    self.tooltipDelay = props[$ "tooltipDelay"] ?? 500;
    
    // Drag props
    self.draggable = props[$ "draggable"] ?? false;
    self.dropzone = props[$ "dropzone"] ?? false;
    self.dragging = false;
    self.dragThreshold = 5;
    self.dragStartX = 0;
    self.dragStartY = 0;
    self.onDragStart = undefined;
    self.onDrag = undefined;
    self.onDragEnd = undefined;
    self.onDrop = undefined;

    

    /** Methods */
    
    // Request a layout update
    function requestUpdate() {
        gml_pragma("forceinline");
        global.UI.requestUpdate(self);
    }

    // Request a redraw
    function requestRedraw() {
        gml_pragma("forceinline");
        global.UI.requestRedraw(self);
    }
    
    // Set the size of the node
    function setSize(w, h) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, w, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, h, flexpanel_unit.point);
        self.requestUpdate();
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
        self.requestUpdate();
        
        return self;
    }
    
    // Remove a child
    function remove(child) {
        gml_pragma("forceinline");
        self.requestUpdate();  
        child.parent = undefined;
        flexpanel_node_remove_child(self.node, child.node);
        
        for (var i = self.childrenLength - 1; i >= 0; i--) {
            if (self.children[i] == child) {
                array_delete(self.children, i, 1);
                self.childrenLength--;
                break;
            }
        }
        
        // Remove child and all its descendants from the spatial tree
        __removeFromSpatialTree(child);
        
        return self;
    }
    
    // Helper: recursively remove element and children from spatial tree
    static __removeFromSpatialTree = function(elem) {
        // Clear hover state and deepestTarget if this element was being tracked
        elem.hovered = false;
        if (global.UI.deepestTarget == elem) {
            global.UI.deepestTarget = undefined;
        }
        
        // Remove this element from spatial tree
        if (variable_struct_exists(elem, "__spatialProxyId") && elem.__spatialProxyId != undefined) {
            global.UI.spatialTree.remove(elem.__spatialProxyId);
            elem.__spatialProxyId = undefined;
        }
        
        // Recursively remove children
        var _children = elem.children;
        var _len = elem.childrenLength;
        for (var i = 0; i < _len; i++) {
            __removeFromSpatialTree(_children[i]);
        }
        
        // Also handle scrollbar if present
        if (variable_struct_exists(elem, "__UiScrollbar") && elem.__UiScrollbar != undefined) {
            __removeFromSpatialTree(elem.__UiScrollbar);
        }
    };
    
    // Remove all children from the node tree (not from the memory, use destroy() for that)
    function clear() {
        gml_pragma("forceinline");
        
        // Remove all children from spatial tree first
        var _children = self.children;
        var _len = is_array(_children) ? array_length(_children) : 0;
        for (var i = 0; i < _len; i++) {
            if (_children[i] != undefined) {
                __removeFromSpatialTree(_children[i]);
            }
        }
        
        flexpanel_node_remove_all_children(self.node);
        self.requestUpdate();
        self.children = [];
        self.childrenLength = 0;
        return self;
    }
    
    // Delete this node and optionally also its children from memory
    function destroy() {
        gml_pragma("forceinline");
        self.requestUpdate();
        
        // Unregister from focus manager if focusable
        if (self.focusable && !self.root) {
            global.UI.__unregisterFocus(self);
        }
        
        // Remove this element and ALL descendants from spatial tree FIRST
        // This also clears hover state and deepestTarget
        __removeFromSpatialTree(self);
        
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
    
    // Remove (if exists) the connected step handlers
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
    
    // Delete the node's children from memory but not the node itself
    function destroyChildren() {
        gml_pragma("forceinline");
        
        for (var i = self.childrenLength - 1; i >= 0; i--) {
            var elem = self.children[i];
            
            // Remove from spatial tree first (recursively for all descendants)
            __removeFromSpatialTree(elem);
            
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
         
        self.requestUpdate();
        self.children = [];
        self.childrenLength = 0;
        return self; 
    }
    
    // Count the children
    function count() {
        gml_pragma("forceinline");
        return self.childrenLength;
    }
    
    // Recursively count all elements
    function countAll() { 
        gml_pragma("forceinline"); 
        var counter = 1;
        
        for (var i = 0; i < self.childrenLength; i++) {
            counter += self.children[i].countAll();
        }
            
        return counter;
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
    
    /** Focus management methods */
    
    // Set focus to this element
    function focus() {
        if (global.UI.focusedElement != undefined && global.UI.focusedElement != self) {
            // Blur the currently focused element first
            if (global.UI.focusedElement[$ "onBlur"] != undefined) {
                global.UI.focusedElement.onBlur();
            }
        }
        
        global.UI.focusedElement = self;
        
        if (self[$ "onFocus"] != undefined) {
            self.onFocus();
        }
        
        global.UI.requestRedraw();
        return self;
    }
    
    // Remove focus from this element
    function blur() {
        if (global.UI.focusedElement == self) {
            if (self[$ "onBlur"] != undefined) {
                self.onBlur();
            }
            
            global.UI.focusedElement = undefined;
            global.UI.requestRedraw();
        }
        return self;
    }
    
    // Check if this element has focus
    function hasFocus() {
        return global.UI.focusedElement == self;
    }
    
    // Get the currently focused element
    function getFocused() {
        return global.UI.focusedElement;
    }
    
    /** Traversal methods */
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
        self.requestUpdate();
    }
    
    function hide() {
        gml_pragma("forceinline");
        flexpanel_node_style_set_display(self.node, flexpanel_display.none);
        self.display = false;
        self.requestUpdate();
    }
    
    // Scrolling bound check    
    function __isInScrollBounds() {
        gml_pragma("forceinline");
        var _scrollableParent = self.scrollableParent;

        if (self.isScrollbar || _scrollableParent == undefined) return true;
        
        // Use parent's scrollTop for cache check (not self.scrollTop which is always 0 for non-scrollable elements)
        var _parentScrollTop = _scrollableParent.scrollTop;
        if (self.__scrollBoundsCachedScrollTop == _parentScrollTop && 
            self.__scrollBoundsCachedValue != undefined && 
            !global.UI.layoutUpdated) {
            return self.__scrollBoundsCachedValue;
        }
        
        self.__scrollBoundsCachedScrollTop = _parentScrollTop;
    
        // Use absolute coordinates (y1/y2) which are already calculated
        // These account for scroll offset and absolute positioning
        var elemTop = self.y1;
        var elemBottom = self.y2;
    
        // Parent's visible area in absolute coordinates
        var visibleTop = _scrollableParent.y1;
        var visibleBottom = _scrollableParent.y2;

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
        self.requestUpdate();
    } 
    
    function getWidth() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_width(self.node).value;
    }
    
    function setHeight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_height(self.node, value, flexpanel_unit.point);
        self.requestUpdate();
    }
    
    function getHeight() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_height(self.node).value;
    }
    
    function setLeft(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.left, value, flexpanel_unit.point);
        self.requestUpdate();
    }
    
    function getLeft() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.left).value;
    }
    
    function setTop(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.top, value, flexpanel_unit.point);
        self.requestUpdate();
    }
    
    function getTop() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.top).value;
    }
    
    function setRight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.right, value, flexpanel_unit.point);
        self.requestUpdate();
    }
    
    function getRight() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.right).value;
    }
    
    function setBottom(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_position(self.node, flexpanel_edge.bottom, value, flexpanel_unit.point);
        self.requestUpdate();
    }
    
    function getBottom() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_position(self.node, flexpanel_edge.bottom).value;
    } 
    
    
    // Margin
    function setMarginTop(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_margin(self.node, flexpanel_edge.top, value);
        self.requestUpdate();
    }
    
    function getMarginTop() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_margin(self.node, flexpanel_edge.top).value;
    }
    
    function setMarginLeft(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_margin(self.node, flexpanel_edge.left, value);
        self.requestUpdate();
    }
    
    function getMarginLeft() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_margin(self.node, flexpanel_edge.left).value;
    }
    
    function setMarginRight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_margin(self.node, flexpanel_edge.right, value);
        self.requestUpdate();
    }
    
    function getMarginRight() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_margin(self.node, flexpanel_edge.right).value;
    }
    
    function setMarginBottom(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_margin(self.node, flexpanel_edge.bottom, value);
        self.requestUpdate();
    }
    
    function getMarginBottom() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_margin(self.node, flexpanel_edge.bottom).value;
    }

    // Padding
    function setPaddingTop(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_padding(self.node, flexpanel_edge.top, value);
        self.requestUpdate();
    }
    
    function getPaddingTop() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_padding(self.node, flexpanel_edge.top).value;
    }
    
    function setPaddingLeft(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_padding(self.node, flexpanel_edge.left, value);
        self.requestUpdate();
    }
    
    function getPaddingLeft() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_padding(self.node, flexpanel_edge.left).value;
    }
    
    function setPaddingRight(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_padding(self.node, flexpanel_edge.right, value);
        self.requestUpdate();
    }
    
    function getPaddingRight() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_padding(self.node, flexpanel_edge.right).value;
    }
    
    function setPaddingBottom(value) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_padding(self.node, flexpanel_edge.bottom, value);
        self.requestUpdate();
    }
    
    function getPaddingBottom() {
        gml_pragma("forceinline");
        return flexpanel_node_style_get_padding(self.node, flexpanel_edge.bottom).value;
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
        if (self.__UiScrollbar != undefined) {
            self.__UiScrollbar.destroy();
        }
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
    
    function onDoubleClick(cb) {
        gml_pragma("forceinline");
        self.addEventListener(UI_EVENT.doubleclick, cb);
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
}
