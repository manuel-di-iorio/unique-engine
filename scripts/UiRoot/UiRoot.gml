global.UI_CLICK_START = undefined;

function UiRoot(style = {}, props = {}): UiNode(style, props) constructor {
    self.root = true;
    self.surface = undefined;
    self.deepestTarget = undefined;
    self.previousTarget = undefined;
    self.needsUpdate = true;
    self.needsRedraw = true;
    self.currentCursor = cr_default;
    self.isScrolling = false;
    self.Overlay = undefined;
    self.Tooltip = undefined;

    self.getOverlay = function() {
        if (self.Overlay == undefined) {
            self.Overlay = new UiNode({ name: "Overlay", position: "absolute", left: 0, top: 0, width: "100%", height: "100%" }, { pointerEvents: false });
            self.add(self.Overlay);
        }
        return self.Overlay;
    }

    self.getTooltip = function() {
        if (self.Tooltip == undefined) {
            var overlay = self.getOverlay();
            self.Tooltip = new UiTooltip();
            overlay.add(self.Tooltip);
        }
        return self.Tooltip;
    }

    // Track modified elements for optimization/debugging
    self.dirtyElements = [];
    self.redrawElements = [];

    function requestRedraw(element = undefined) {
        gml_pragma("forceinline");
        self.needsRedraw = true;
        if (element != undefined) array_push(self.redrawElements, element);
    }

    function requestUpdate(element = undefined) {
        gml_pragma("forceinline");
        self.needsUpdate = true;
        if (element != undefined) array_push(self.dirtyElements, element);
    }
    
    function setCursor(cursor) {
        gml_pragma("forceinline");
        if (self.currentCursor != cursor) {
            self.currentCursor = cursor;
            window_set_cursor(cursor);
        }
    }
    self.layoutUpdated = undefined;
    self.surface = undefined;
    self.mouseX = undefined;
    self.mouseY = undefined;
    self.mouseXPrev = undefined;
    self.mouseYPrev = undefined;
    self.stepHandlers = [];
    self.hoveredElements = [];
    
    // Double click tracking
    self.lastClickTime = -1;
    self.lastClickTarget = undefined;
    self.doubleClickThreshold = 500;
    
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
            var _focused = self.focusedElement;
            currentIndex = array_find_index(self.focusableElements, method({ el: _focused }, function(item) {
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
            var _focused = self.focusedElement;
            currentIndex = array_find_index(self.focusableElements, method({ el: _focused }, function(item) {
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
        global.UI.requestUpdate();
        
        return self;
    } 
    
    /** Update */
    function __updateElemLayout(elem, _inheritedScrollableParent = undefined, _inheritedVisibility = true) {
        gml_pragma("forceinline");

        // Optimization: Resolve ancestor scrollable parent down the tree
        var _scrollableParent = _inheritedScrollableParent;
        if (!elem.isScrollbar) {
            elem.scrollableParent = _scrollableParent;
        }
        
        // Store the layout position data of this element
        elem.layout = flexpanel_node_layout_get_position(elem.node, false);
        elem.width = elem.layout.width;
        elem.height = elem.layout.height;
        elem.x1 = elem.layout.left - (elem.scrollableParent ? elem.scrollableParent.scrollLeft : 0); 
        elem.y1 = elem.layout.top - (elem.scrollableParent ? elem.scrollableParent.scrollTop : 0);
        elem.x2 = elem.x1 + elem.width; 
        elem.y2 = elem.y1 + elem.height;
        elem.xp1 = elem.x1 + elem.layout.paddingLeft;
        elem.yp1 = elem.y1 + elem.layout.paddingTop;
        elem.xp2 = elem.x2 - elem.layout.paddingRight;
        elem.yp2 = elem.y2 - elem.layout.paddingBottom;
        
        // Check visibility AFTER coordinates are updated (isVisible uses y1/y2 for scroll bounds check)
        var _isVisible = _inheritedVisibility && elem.isVisible();
        
        // Assign draw index (matches render order)
        elem.__drawIndex = self.__layoutDrawIndex++;

        // Update element in the spatial partition tree (incremental - no clear!)
        if (_isVisible && elem.pointerEvents) {
            // Clip bounds to scroll parent's visible area so partially-scrolled-out
            // elements cannot be clicked in their invisible overflow region.
            var _treeX1 = elem.x1;
            var _treeY1 = elem.y1;
            var _treeX2 = elem.x2;
            var _treeY2 = elem.y2;
            if (!elem.isScrollbar && _scrollableParent != undefined) {
                _treeX1 = max(_treeX1, _scrollableParent.x1);
                _treeY1 = max(_treeY1, _scrollableParent.y1);
                _treeX2 = min(_treeX2, _scrollableParent.x2);
                _treeY2 = min(_treeY2, _scrollableParent.y2);
            }
            
            // Check if element already has a valid proxy
            var hasProxy = variable_struct_exists(elem, "__spatialProxyId") && elem.__spatialProxyId != undefined;
            
            if (hasProxy) {
                // Update existing proxy position
                self.spatialTree.move(elem.__spatialProxyId, _treeX1, _treeY1, _treeX2, _treeY2);
                // Update the drawIndex in the tree node
                self.spatialTree.updateDrawIndex(elem.__spatialProxyId, elem.__drawIndex);
            } else {
                // Insert new proxy
                elem.__spatialProxyId = self.spatialTree.insert(elem, _treeX1, _treeY1, _treeX2, _treeY2);
            }
        } else {
            // Element is not visible/interactive - remove from tree if present
            if (variable_struct_exists(elem, "__spatialProxyId") && elem.__spatialProxyId != undefined) {
                self.spatialTree.remove(elem.__spatialProxyId);
                elem.__spatialProxyId = undefined;
            }
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
        if (elem.__UiScrollbar != undefined || elem.__UiScrollbarH != undefined) {
            _nextScrollableParent = elem;
        }
        
        // Run the update on the children
        var _children = elem.children;
        var _len = elem.childrenLength;
        for (var i = 0; i < _len; i++) {
            var child = _children[i];
            if (elem.root && (child == elem.Overlay || child == elem.Tooltip)) continue;
            self.__updateElemLayout(child, _nextScrollableParent, _isVisible);
        }
        
        // Special case for scrollbars: they are drawn after children
        if (elem.__UiScrollbar != undefined) {
            self.__updateElemLayout(elem.__UiScrollbar, _nextScrollableParent, _isVisible);
            elem.__UiScrollbar.Thumb.__drawIndex = self.__layoutDrawIndex++;
        }
        if (elem.__UiScrollbarH != undefined) {
            self.__updateElemLayout(elem.__UiScrollbarH, _nextScrollableParent, _isVisible);
            elem.__UiScrollbarH.Thumb.__drawIndex = self.__layoutDrawIndex++;
        }

        // Run layout updates on Overlay and Tooltip last if this is root
        if (elem.root) {
            if (elem.Overlay != undefined) {
                self.__updateElemLayout(elem.Overlay, _nextScrollableParent, _isVisible);
            }
            if (elem.Tooltip != undefined) {
                self.__updateElemLayout(elem.Tooltip, _nextScrollableParent, _isVisible);
            }
        }
    }
    
    /// @desc Update a single element's position in the spatial tree without full rebuild.
    ///       Use this for elements that move frequently (like tooltips, drag previews, etc.)
    ///       The element must already have a __spatialProxyId from a previous layout.
    /// @param {Struct} elem The UI element to update
    function updateElementPosition(elem) {
        // Clip bounds to scroll parent's visible area
        var _x1 = elem.x1, _y1 = elem.y1, _x2 = elem.x2, _y2 = elem.y2;
        var _sp = elem[$ "scrollableParent"];
        if (!elem.isScrollbar && _sp != undefined) {
            _x1 = max(_x1, _sp.x1);
            _y1 = max(_y1, _sp.y1);
            _x2 = min(_x2, _sp.x2);
            _y2 = min(_y2, _sp.y2);
        }
        
        if (!variable_struct_exists(elem, "__spatialProxyId") || elem.__spatialProxyId == undefined) {
            // Element not in tree yet, insert it
            if (elem.pointerEvents && elem.visible) {
                elem.__spatialProxyId = self.spatialTree.insert(elem, _x1, _y1, _x2, _y2);
            }
            return;
        }
        
        // Move existing proxy
        self.spatialTree.move(elem.__spatialProxyId, _x1, _y1, _x2, _y2);
    }
    
    /// @desc Remove a single element from the spatial tree (for elements going invisible)
    /// @param {Struct} elem The UI element to remove
    function removeElementFromTree(elem) {
        if (variable_struct_exists(elem, "__spatialProxyId") && elem.__spatialProxyId != undefined) {
            self.spatialTree.remove(elem.__spatialProxyId);
            elem.__spatialProxyId = undefined;
        }
    }
    
    function __processLayout() {
        gml_pragma("forceinline");
        self.needsUpdate = false;
        self.layoutUpdated = true;
        flexpanel_calculate_layout(self.node, "100%", "100%", flexpanel_direction.LTR);
        
        self.__layoutDrawIndex = 0;
        
        // Update the elements position when the layout changes
        self.__updateElemLayout(self);
    }

    // Calculate the layout of this node and its children
    function update() {
        gml_pragma("forceinline"); 
        self.layoutUpdated = false;
        
        // Lazy initialize Overlay and Tooltip layers
        self.getOverlay();
        self.getTooltip();
        
        if (self.needsUpdate) {
            self.__processLayout();
        }
        
        // Cache mouse vars
        self.mouseX = device_mouse_x_to_gui(0);
        self.mouseY = device_mouse_y_to_gui(0);
        self.mouseChanged = self.mouseX != self.mouseXPrev || self.mouseY != self.mouseYPrev;
        self.mouseReleased = mouse_check_button_released(mb_any);
          
        // Check the hover/unhover events
        var _currentlyHovered = self.deepestTarget;
        // Update deepestTarget when mouse moved OR when layout changed (e.g., dropdown opened under mouse)
        if (self.mouseChanged || self.layoutUpdated) {
            self.deepestTarget = self.spatialTree.getTopmostAtPoint(self.mouseX, self.mouseY);
            
            // Skip hover events during scroll
            if (!self.isScrolling) {
                // Unhover the previous element first (before setting new hover)
                if (_currentlyHovered != undefined && _currentlyHovered != self.deepestTarget) {
                    if (self.draggedElement == undefined) {
                        self.setCursor(cr_default);
                    }
                    
                    _currentlyHovered.hovered = false;
                    self.dispatchEvent(UI_EVENT.mouseleave, _currentlyHovered); 
                    self.dispatchEvent(UI_EVENT.mouseout, _currentlyHovered);
                    self.previousTarget = undefined;
                    self.requestRedraw();
                }
                
                // Set hover on new element (only dispatch events if it's a new hover target)
                if (self.deepestTarget != undefined) {
                    var _elem = self.deepestTarget;
                    var _wasAlreadyHovered = _elem.hovered;
                    _elem.hovered = true;
                    
                    // Only dispatch enter/over if this is a NEW hover target
                    if (!_wasAlreadyHovered) {
                        self.dispatchEvent(UI_EVENT.mouseenter, _elem); 
                        self.dispatchEvent(UI_EVENT.mouseover, _elem);
                        self.requestRedraw();
                    }
                    
                    if (_elem.handpoint && self.currentCursor == cr_default && self.draggedElement == undefined) {
                        self.setCursor(cr_handpoint);
                    }
                }
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
                    self.setCursor(cr_size_all);
                    
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
                    // feather ignore GM1019
                    global.UI.Tooltip.show(self.tooltipElement, self.tooltipElement.tooltip);
                }
                self.tooltipTimer = -1; // Tooltip shown
            }
        }
        
        
        // Click event handled only on root
        // Cache target and check if valid (not destroyed) - target might be destroyed during event dispatch
        var _target = self.deepestTarget;
        
        if (mouse_check_button_pressed(mb_any)) {
             // We check for any button press (left, right, middle) to ensure focus is lost when clicking outside
             if (self.focusedElement != undefined) {
                 var _shouldBlur = true;
                 
                 if (_target != undefined) {
                     if (_target[$ "focusable"] ?? false) {
                         _shouldBlur = false;
                     } else {
                         // Check if target is a descendant of the focused element
                         var _curr = _target;
                         while (_curr != undefined) {
                             if (_curr == self.focusedElement) {
                                 _shouldBlur = false;
                                 break;
                             }
                             _curr = _curr.parent;
                         }
                     }
                 }
                 
                 if (_shouldBlur) {
                     self.focusedElement.blur();
                 }
             }
         }

        if (_target != undefined && !(_target[$ "destroyed"] ?? false)) {
            // Wheel events
            if (mouse_wheel_up()) {
                self.isScrolling = true;
                global.UI.dispatchEvent(UI_EVENT.wheelup, _target);
                self.isScrolling = false;
            }
            if (mouse_wheel_down()) {
                self.isScrolling = true;
                global.UI.dispatchEvent(UI_EVENT.wheeldown, _target);
                self.isScrolling = false;
            }
            
            if (mouse_check_button_pressed(mb_any)) {
                global.UI_CLICK_START = _target;
                global.UI.dispatchEvent(UI_EVENT.mousedown, _target);

                // Check again if target is still valid after mousedown event
                if (mouse_check_button_pressed(mb_left) && !(_target[$ "destroyed"] ?? false)) {
                    // Search for the nearest draggable element in the hierarchy
                    var dragSearch = _target;
                    while (dragSearch != undefined) {
                        if (dragSearch[$ "draggable"] ?? false) {
                            self.potentialDraggedElement = dragSearch;
                            dragSearch.dragStartX = self.mouseX;
                            dragSearch.dragStartY = self.mouseY;
                            break;
                        }
                        dragSearch = dragSearch.parent;
                    }
                }
            }
        } else if (_target != undefined && (_target[$ "destroyed"] ?? false)) {
            // Clear destroyed element reference
            self.deepestTarget = undefined;
        }
        
        
        // Handle mouse release
        if (self.mouseReleased) {
            var releasedButton = mb_left; // Default to left if we can't determine
            if (device_mouse_check_button_released(0, mb_left)) releasedButton = mb_left;
            else if (device_mouse_check_button_released(0, mb_right)) releasedButton = mb_right;
            else if (device_mouse_check_button_released(0, mb_middle)) releasedButton = mb_middle;

            // First, handle the drag end if we got a dragged element
            if (self.draggedElement != undefined) {
                self.draggedElement.dragging = false;
                self.setCursor(cr_default);
                
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

                if (releasedButton == mb_left) {
                    global.UI.dispatchEvent(UI_EVENT.click, self.deepestTarget);
                    
                    // Handle double click
                    var now = current_time;
                    if (self.lastClickTarget == self.deepestTarget && (now - self.lastClickTime) < self.doubleClickThreshold) {
                        global.UI.dispatchEvent(UI_EVENT.doubleclick, self.deepestTarget);
                        self.lastClickTime = -1; // Reset to avoid triple-click as double-click
                        self.lastClickTarget = undefined;
                    } else {
                        self.lastClickTime = now;
                        self.lastClickTarget = self.deepestTarget;
                    }
                } else if (releasedButton == mb_right) {
                    global.UI.dispatchEvent(UI_EVENT.contextmenu, self.deepestTarget);
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
        
        // Final layout pass: if event handlers (like onClick) modified the UI structure,
        // recalculate layout immediately to avoid a blank frame (flash) in the Draw event.
        if (self.needsUpdate) {
            self.__processLayout();
        }

        // Run step handlers from a stable snapshot so handlers can safely unregister during callbacks.
        var _stepHandlersLength = array_length(self.stepHandlers);
        var _stepHandlers = [];
        array_copy(_stepHandlers, 0, self.stepHandlers, 0, _stepHandlersLength);
        for (var i = _stepHandlersLength - 1; i >= 0; i--) {
            var _entry = _stepHandlers[i];
            if (_entry == undefined) continue;
            if (_entry[0] == undefined) continue;

            var _owner = _entry[1];
            if (_owner != undefined && (_owner.destroyed || _owner.hasStepEvent != true)) continue;

            _entry[0](self.layoutUpdated);
        }
        
        self.mouseXPrev = self.mouseX;
        self.mouseYPrev = self.mouseY;

        // Clear dirty elements list for the next frame
        if (array_length(self.dirtyElements) > 0) {
            self.dirtyElements = [];
        }
    }
    
    /** Draw */
    function __renderChild(elem, debug = false, inheritedScissor = undefined) {
        gml_pragma("forceinline");
        if (!elem.isVisible() || !elem.mounted) return;

        elem.__drawIndex = self.rootDrawIndex++;
        var _scissor = inheritedScissor;
        var _ownScissor = false;
        
        // Set up scissor for scrollable elements
        if (elem.__UiScrollbar != undefined || elem.__UiScrollbarH != undefined) {
            _ownScissor = true;
            var _prevScissor = gpu_get_scissor();
            
            // Calculate new scissor, intersecting with any inherited scissor
            var sx1 = elem.x1;
            var sy1 = elem.y1;
            var sw = elem.x2 - elem.x1;
            var sh = elem.y2 - elem.y1;
            
            if (inheritedScissor != undefined) {
                // Intersect with inherited scissor
                var ix1 = max(sx1, inheritedScissor[0]);
                var iy1 = max(sy1, inheritedScissor[1]);
                var ix2 = min(sx1 + sw, inheritedScissor[0] + inheritedScissor[2]);
                var iy2 = min(sy1 + sh, inheritedScissor[1] + inheritedScissor[3]);
                sx1 = ix1;
                sy1 = iy1;
                sw = max(0, ix2 - ix1);
                sh = max(0, iy2 - iy1);
            }
            
            _scissor = [sx1, sy1, sw, sh];
            __uui_set_scissor(sx1, sy1, sw, sh);
        }

        // Run the draw method of the element
        if (elem.onDraw != undefined) elem.onDraw();
        
        // Render the children (pass scissor down)
        for (var i = 0; i < elem.childrenLength; i++) {
            var child = elem.children[i];
            if (child.isScrollbar) continue;
            if (elem.root && (child == elem.Overlay || child == elem.Tooltip)) continue;
            self.__renderChild(child, debug, _scissor);
        }
        
        // Reset the previous scissor and render the scrollbar
        if (_ownScissor) {
            // Restore to inherited scissor or no scissor
            if (inheritedScissor != undefined) {
                __uui_set_scissor(inheritedScissor[0], inheritedScissor[1], inheritedScissor[2], inheritedScissor[3]);
            } else {
                __uui_set_scissor(0, 0, self.width, self.height);
            }
            if (elem.__UiScrollbar != undefined) {
                self.__renderChild(elem.__UiScrollbar, debug, inheritedScissor);
                elem.__UiScrollbar.Thumb.__drawIndex = self.rootDrawIndex++;
                elem.__UiScrollbar.Thumb.onDraw();
            }
            if (elem.__UiScrollbarH != undefined) {
                self.__renderChild(elem.__UiScrollbarH, debug, inheritedScissor);
                elem.__UiScrollbarH.Thumb.__drawIndex = self.rootDrawIndex++;
                elem.__UiScrollbarH.Thumb.onDraw();
            }
        }

        // Draw Overlay and Tooltip last if this is root
        if (elem.root) {
            if (elem.Overlay != undefined) {
                self.__renderChild(elem.Overlay, debug, _scissor);
            }
            if (elem.Tooltip != undefined) {
                self.__renderChild(elem.Tooltip, debug, _scissor);
            }
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
        
        if (surface_exists(self.surface)) {
            if (surface_get_width(self.surface) != self.width || surface_get_height(self.surface) != self.height) {
                surface_free(self.surface);
            }
        }
        
        if (!surface_exists(self.surface)) {
            self.surface = surface_create(self.width, self.height);
            self.requestRedraw();
        }
        
        self.rootDrawIndex = 0; 
        
        // Ensure layout is up to date before rendering to prevent flashes
        if (self.needsUpdate) {
            self.__processLayout();
        }

        if (self.layoutUpdated || self.needsRedraw) {
            self.needsRedraw = false;
            var currentBlendMode = gpu_get_blendmode_ext_sepalpha();
            gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_inv_dest_alpha, bm_one);
            surface_set_target(self.surface);
            draw_clear_alpha(c_black, 0);
            self.__renderChild(self, debug);
            surface_reset_target();
            // feather ignore GM1020
            gpu_set_blendmode_ext_sepalpha(currentBlendMode);
        }
        
        draw_surface(self.surface, 0, 0);
        
        // Clear redraw elements list for the next frame
        if (array_length(self.redrawElements) > 0) {
            self.redrawElements = [];
        }
    } 
    
    
    setName("UniqueUI");
}

global.UI = new UiRoot();
