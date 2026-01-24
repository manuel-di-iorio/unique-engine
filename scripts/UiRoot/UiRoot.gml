global.UI_CLICK_START = undefined;

function UiRoot(style = {}, props = {}): UiNode(style, props) constructor {
    self.root = true;
    self.surface = undefined;
    self.deepestTarget = undefined;
    self.previousTarget = undefined;
    self.needsUpdate = true;
    self.needsRedraw = true;

    // Benchmarking
    self.__benchmarks = {
        updateRequests: 0,
        redrawRequests: 0,
        lastUpdateSource: "unknown",
        updateHistory: [],
        isEnabled: false
    };

    function requestRedraw(source = "unknown") {
        gml_pragma("forceinline");
        self.needsRedraw = true;
        if (self.__benchmarks.isEnabled) self.__benchmarks.redrawRequests++;
    }

    function requestUpdate(source = "unknown") {
        gml_pragma("forceinline");
        self.needsUpdate = true;
        if (self.__benchmarks.isEnabled) {
            self.__benchmarks.updateRequests++;
            self.__benchmarks.lastUpdateSource = source;
            if (array_length(self.__benchmarks.updateHistory) > 100) array_delete(self.__benchmarks.updateHistory, 0, 1);
            array_push(self.__benchmarks.updateHistory, { source: source, time: current_time });
        }
    }

    function getBenchmarkSummary() {
        if (!self.__benchmarks.isEnabled) return "Benchmarks are disabled. Set global.UI.__benchmarks.isEnabled = true to start.";
        
        var summary = "--- UI Benchmarks ---\n";
        summary += "Update Requests: " + string(self.__benchmarks.updateRequests) + "\n";
        summary += "Redraw Requests: " + string(self.__benchmarks.redrawRequests) + "\n";
        summary += "Last Update Source: " + string(self.__benchmarks.lastUpdateSource) + "\n";
        summary += "Recent History:\n";
        
        var historyLen = array_length(self.__benchmarks.updateHistory);
        var startIdx = max(0, historyLen - 10);
        for (var i = historyLen - 1; i >= startIdx; i--) {
            var entry = self.__benchmarks.updateHistory[i];
            summary += "  [" + string(entry.time) + "] " + string(entry.source) + "\n";
        }
        return summary;
    }
    self.layoutUpdated = undefined;
    self.surface = undefined;
    self.mouseX = undefined;
    self.mouseY = undefined;
    self.mouseXPrev = undefined;
    self.mouseYPrev = undefined;
    self.stepHandlers = [];
    self.hoveredElements = [];
    
    // Focus management
    self.focusedElement = undefined;
    self.focusableElements = [];
    
    // Register an element as focusable
    function __registerFocus(element) {
        if (array_find_index(self.focusableElements, method({ element }, function(item) {
            return item == element;
        })) == -1) {
            array_insert(self.focusableElements, 0, element);
        }
    }
    
    // Unregister an element from being focusable
    function __unregisterFocus(element) {
        var index = array_find_index(self.focusableElements, method({ element }, function(item) {
            return item == element;
        }));
        
        if (index != -1) {
            array_delete(self.focusableElements, index, 1);
        }
        
        if (self.focusedElement == element) {
            self.focusedElement = undefined;
        }
    }
    
    // Check if any element is currently focused
    function hasAnyFocus() {
        return self.focusedElement != undefined;
    }
    
    // Cycle focus to the next focusable element
    function focusNext() {
        if (array_length(self.focusableElements) == 0) return;
        
        var currentIndex = -1;
        if (self.focusedElement != undefined) {
            currentIndex = array_find_index(self.focusableElements, method({ el: self.focusedElement }, function(item) {
                return item == el;
            }));
        }
        
        var nextIndex = (currentIndex + 1) % array_length(self.focusableElements);
        var nextElement = self.focusableElements[nextIndex];
        
        var attempts = 0;
        while ((nextElement[$ "visible"] == false || nextElement[$ "disabled"] == true) && 
               attempts < array_length(self.focusableElements)) {
            nextIndex = (nextIndex + 1) % array_length(self.focusableElements);
            nextElement = self.focusableElements[nextIndex];
            attempts++;
        }
        
        if (nextElement[$ "visible"] != false && nextElement[$ "disabled"] != true) {
            nextElement.focus();
        }
    }
    
    // Cycle focus to the previous focusable element
    function focusPrevious() {
        if (array_length(self.focusableElements) == 0) return;
        
        var currentIndex = -1;
        if (self.focusedElement != undefined) {
            currentIndex = array_find_index(self.focusableElements, method({ el: self.focusedElement }, function(item) {
                return item == el;
            }));
        }
        
        var prevIndex = currentIndex - 1;
        if (prevIndex < 0) prevIndex = array_length(self.focusableElements) - 1;
        
        var prevElement = self.focusableElements[prevIndex];
        
        var attempts = 0;
        while ((prevElement[$ "visible"] == false || prevElement[$ "disabled"] == true) && 
               attempts < array_length(self.focusableElements)) {
            prevIndex--;
            if (prevIndex < 0) prevIndex = array_length(self.focusableElements) - 1;
            prevElement = self.focusableElements[prevIndex];
            attempts++;
        }
        
        if (prevElement[$ "visible"] != false && prevElement[$ "disabled"] != true) {
            prevElement.focus();
        }
    }
    
    // Clear focus and the list of focusable elements
    function clearAllFocused() {
        if (self.focusedElement != undefined) {
            self.focusedElement.blur();
        }
        self.focusableElements = [];
    }

    // Spatial tree (Dynamic AABB Tree 2D)
    self.spatialTree = new DynamicAABBTree2D(512);
    self.__layoutDrawIndex = 0;
    
    // Root drag props
    self.potentialDraggedElement = undefined;
    self.draggedElement = undefined;
    
    // Tooltip props
    self.tooltipElement = undefined;
    self.tooltipTimer = -1;
    
    // Set the size of the root node
    // @override
    function setSize(w, h) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, w, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, h, flexpanel_unit.point);
        global.UI.requestUpdate("setSize");
        
        return self;
    } 
    
    /** Update */
    function __updateElemLayout(elem, _inheritedScrollableParent = undefined, _inheritedVisibility = true) {
        gml_pragma("forceinline");
         
        // Optimization: Resolve ancestor visibility down the tree
        var _isVisible = _inheritedVisibility && elem.isVisible();

        // Optimization: Resolve ancestor scrollable parent down the tree
        var _scrollableParent = _inheritedScrollableParent;
        if (!elem.isScrollbar) {
            elem.scrollableParent = _scrollableParent;
        }
        
        // Store the layout position data of this element
        elem.layout = flexpanel_node_layout_get_position(elem.node, false);
        elem.width = elem.layout.width;
        elem.height = elem.layout.height;
        elem.x1 = elem.layout.left; 
        elem.y1 = elem.layout.top - (elem.scrollableParent ? elem.scrollableParent.scrollTop : 0);
        elem.x2 = elem.layout.left + elem.width; 
        elem.y2 = elem.y1 + elem.height;
        elem.xp1 = elem.x1 + elem.layout.paddingLeft;
        elem.yp1 = elem.y1 + elem.layout.paddingTop;
        elem.xp2 = elem.x2 - elem.layout.paddingRight;
        elem.yp2 = elem.y2 - elem.layout.paddingBottom;
        
        // Assign draw index (matches render order)
        elem.__drawIndex = self.__layoutDrawIndex++;

        // Add the element to the spatial partition tree
        // Optimization: Only add if visible and interactive
        if (_isVisible && elem.pointerEvents) {
            self.spatialTree.insert(elem, elem.x1, elem.y1, elem.x2, elem.y2);
        }
        
        // Run the onMount method, if not yet executed for this element
        if (!elem.mounted) {
            elem.mounted = true;
            
            // Register focusable elements
            if (elem.focusable) {
                self.__registerFocus(elem);
            }
            
            if (elem.onMount != undefined) elem.onMount();
        }
        
        // Determine next scrollable parent to pass to children
        var _nextScrollableParent = _scrollableParent;
        if (elem.__UiScrollbar != undefined) {
            _nextScrollableParent = elem;
        }
        
        // Run the update on the children
        var _children = elem.children;
        var _len = elem.childrenLength;
        for (var i = 0; i < _len; i++) {
            self.__updateElemLayout(_children[i], _nextScrollableParent, _isVisible);
        }
        
        // Special case for scrollbars: they are drawn after children
        if (elem.__UiScrollbar != undefined) {
            self.__updateElemLayout(elem.__UiScrollbar, _nextScrollableParent, _isVisible);
            elem.__UiScrollbar.Thumb.__drawIndex = self.__layoutDrawIndex++;
            // Thumb doesn't need to be in the spatial tree as it's part of the scrollbar interaction
        }
    }
    
    // Calculate the layout of this node and its children
    function update() {
        gml_pragma("forceinline"); 
        self.layoutUpdated = false;
        
        if (self.needsUpdate) {
            self.needsUpdate = false;
            self.layoutUpdated = true;
            flexpanel_calculate_layout(self.node, undefined, undefined, flexpanel_direction.LTR);
            
            // Clear and rebuild the spatial tree
            self.spatialTree.clear();
            self.__layoutDrawIndex = 0;
            
            // Update the elements position when the layout changes
            self.__updateElemLayout(self);
        }
        
        // Cache mouse vars
        self.mouseX = device_mouse_x_to_gui(0);
        self.mouseY = device_mouse_y_to_gui(0);
        self.mouseChanged = self.mouseX != self.mouseXPrev || self.mouseY != self.mouseYPrev;
        self.mouseReleased = mouse_check_button_released(mb_any);
        
        // Check the hover/unhover events
        var _currentlyHovered = self.deepestTarget;
        if (self.mouseChanged) {
            self.deepestTarget = self.spatialTree.getTopmostAtPoint(self.mouseX, self.mouseY);
            
            if (self.deepestTarget != undefined) {
                var _elem = self.deepestTarget;
                _elem.hovered = true;
                self.dispatchEvent(UI_EVENT.mouseenter, _elem); 
                self.dispatchEvent(UI_EVENT.mouseover, _elem);
                
                if (_elem.handpoint && window_get_cursor() == cr_default && self.draggedElement == undefined) {
                    window_set_cursor(cr_handpoint);
                }
            }

            // Unhover the previous element
            if (_currentlyHovered != undefined && _currentlyHovered != self.deepestTarget) {
                if (self.draggedElement == undefined) {
                    window_set_cursor(cr_default);
                }
                
                _currentlyHovered.hovered = false;
                self.dispatchEvent(UI_EVENT.mouseleave, _currentlyHovered); 
                self.dispatchEvent(UI_EVENT.mouseout, _currentlyHovered);
                self.previousTarget = undefined;
            }
            
            self.previousTarget = self.deepestTarget;
            
            // Process drag detection if we have a potential drag element
            if (self.potentialDraggedElement != undefined && !self.potentialDraggedElement.dragging) {
                if (point_distance(self.mouseX, self.mouseY, self.potentialDraggedElement.dragStartX, self.potentialDraggedElement.dragStartY) 
                     >= self.potentialDraggedElement.dragThreshold) {
                    // Start actual dragging
                    self.draggedElement = self.potentialDraggedElement;
                    self.draggedElement.dragging = true;
                    self.potentialDraggedElement = undefined;
                    window_set_cursor(cr_size_all);
                    
                    if (self.draggedElement.onDragStart != undefined) {
                        self.draggedElement.onDragStart(self.draggedElement);
                    }
                }
            }
        }
        
        // Tooltip logic
        if (self.deepestTarget != self.tooltipElement) {
            // Target changed
            if (global.UI.Tooltip != undefined) global.UI.Tooltip.hide();
            self.tooltipElement = self.deepestTarget;
            self.tooltipTimer = -1;
            
            if (self.tooltipElement != undefined && self.tooltipElement.tooltip != undefined) {
                self.tooltipTimer = current_time + self.tooltipElement.tooltipDelay;
            }
        } else if (self.tooltipElement != undefined && self.tooltipTimer != -1) {
            // Waiting for timer
            if (current_time >= self.tooltipTimer) {
                if (global.UI.Tooltip != undefined) {
                    global.UI.Tooltip.show(self.tooltipElement, self.tooltipElement.tooltip);
                }
                self.tooltipTimer = -1; // Tooltip shown
            }
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
            
            if (mouse_check_button_pressed(mb_any)) {
                global.UI_CLICK_START = self.deepestTarget;
                global.UI.dispatchEvent(UI_EVENT.mousedown, self.deepestTarget);

                // We check for any button press (left, right, middle) to ensure focus is lost when clicking outside
                if (self.focusedElement != undefined && (self.deepestTarget == undefined || !self.deepestTarget.focusable)) {
                    self.focusedElement.blur();
                }

                if (mouse_check_button_pressed(mb_left)) {
                    if (self.deepestTarget.draggable) {
                        self.potentialDraggedElement = self.deepestTarget;
                        self.potentialDraggedElement.dragStartX = self.mouseX;
                        self.potentialDraggedElement.dragStartY = self.mouseY;
                    }
                }
            }
        }
        
        
        // Handle mouse release
        if (self.mouseReleased) {
            // First, handle the drag end if we got a dragged element
            if (self.draggedElement != undefined) {
                self.draggedElement.dragging = false;
                window_set_cursor(cr_default);
                
                // Run the onDrop method on the dropzone
                if (self.deepestTarget != undefined && self.deepestTarget.dropzone && 
                    self.deepestTarget != self.draggedElement && self.deepestTarget.onDrop != undefined) {
                    self.deepestTarget.onDrop(self.draggedElement, self.deepestTarget);
                }
                
                // Run the onDragEnd on the dragged element anyway
                if (self.draggedElement.onDragEnd != undefined) {
                    self.draggedElement.onDragEnd(self.draggedElement, self.deepestTarget);
                }
                
                self.draggedElement = undefined;
            }
            
            // Then handle the normal click (if it was not a drag operation)
            else if (self.deepestTarget != undefined && self.deepestTarget == global.UI_CLICK_START) {
                global.UI.dispatchEvent(UI_EVENT.mouseup, self.deepestTarget);

                if (mouse_lastbutton == mb_left) {
                    global.UI.dispatchEvent(UI_EVENT.click, self.deepestTarget);
                }
            }
            
            global.UI_CLICK_START = undefined;
            self.potentialDraggedElement = undefined;
        }
        
        // Handle Tab navigation for focus management
        if (keyboard_check_pressed(vk_tab)) {
            if (keyboard_check(vk_shift)) {
                self.focusPrevious();
            } else {
                self.focusNext();
            }
        }
        
        // Run the step handlers
        for (var i = array_length(self.stepHandlers) - 1; i >= 0; i--) {
            self.stepHandlers[i][0](self.layoutUpdated);
        }
        
        self.mouseXPrev = self.mouseX;
        self.mouseYPrev = self.mouseY;
    }
    
    /** Draw */
    function __renderChild(elem, debug = false) {
        gml_pragma("forceinline");
        if (!elem.isVisible() || !elem.mounted) return;

        elem.__drawIndex = self.rootDrawIndex++;
        var _scissor = undefined;

        // Draw the border if enabled
        if (elem.border) {
            draw_set_color(elem.borderColor);
            draw_rectangle(elem.x1, elem.y1, elem.x2, elem.y2, true);
        }
        
        if (elem.__UiScrollbar != undefined) {
            _scissor = gpu_get_scissor();
            gpu_set_scissor(elem.x1, elem.y1, elem.x2 - elem.x1, elem.y2 - elem.y1);
        }

        // Run the draw method of the element
        if (elem.onDraw != undefined) elem.onDraw();
        
        // Render the children
        for (var i = 0; i < elem.childrenLength; i++) {
            var child = elem.children[i];
            if (child.isScrollbar) continue;
            self.__renderChild(child, debug);
        }
        
        // Reset the previous scissor and render the scrollbar
        if (elem.__UiScrollbar != undefined && _scissor != undefined) {
            gpu_set_scissor(_scissor);
            self.__renderChild(elem.__UiScrollbar, debug);
            elem.__UiScrollbar.Thumb.__drawIndex = self.rootDrawIndex++;
            elem.__UiScrollbar.Thumb.onDraw();
        }
        
        // Draw the debug element bounds
        if (debug) {
            draw_set_color(elem.hovered ? c_red : c_yellow);
            draw_rectangle(elem.xp1, elem.yp1, elem.xp2, elem.yp2, true);
            
            var _name = flexpanel_node_get_name(elem.node);
            if (elem.hovered && _name != undefined) {
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text(~~mean(elem.x1, elem.x2), ~~mean(elem.y1, elem.y2), _name);
            }
        }
    }
    
    // Render the node and its children to the static surface
    // Pass `true` as first argument to draw the nodes bounds and their (optional) name.
    function render(debug = false) {
        gml_pragma("forceinline");
        if (!self.width) return;
        
        if (!surface_exists(self.surface)) {
            self.surface = surface_create(self.width, self.height);
            self.requestRedraw("UiRoot.render.surfaceLost");
        }
        
        self.rootDrawIndex = 0; 
        
        if (self.layoutUpdated || self.needsRedraw) {
            self.needsRedraw = false;
            var currentBlendMode = gpu_get_blendmode_ext_sepalpha();
            gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_inv_dest_alpha, bm_one);
            surface_set_target(self.surface);
            draw_clear_alpha(c_black, 0);
            self.__renderChild(self, debug);
            surface_reset_target();
            gpu_set_blendmode_ext_sepalpha(currentBlendMode);
        }
        
        draw_surface(self.surface, 0, 0);
    } 
    
    
    setName("UniqueUI");
}

global.UI = new UiRoot();
