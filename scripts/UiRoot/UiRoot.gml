global.UI_CLICK_START = undefined;

function UiRoot(style = {}, props = {}): UiNode(style, props) constructor {
    self.root = true;
    self.surface = undefined;
    self.deepestTarget = undefined;
    self.previousTarget = undefined;
    self.needsUpdate = true;
    self.needsRedraw = true;
    self.layoutUpdated = undefined;
    self.surface = undefined;
    self.mouseX = undefined;
    self.mouseY = undefined;
    self.mouseXPrev = undefined;
    self.mouseYPrev = undefined;
    self.stepHandlers = [];
    self.hoveredElements = [];

    // Spatial partition grid props
    self.grid = ds_grid_create(0, 0);
    self.gridW = 0;
    self.gridH = 0;
    self.gridSize = 64;
    
    // Root drag props
    self.potentialDraggedElement = undefined;
    self.draggedElement = undefined;
    
    // Set the size of the root node
    // @override
    function setSize(w, h) {
        gml_pragma("forceinline");
        flexpanel_node_style_set_width(self.node, w, flexpanel_unit.point);
        flexpanel_node_style_set_height(self.node, h, flexpanel_unit.point);
        global.UI.needsUpdate = true;
        
        // Resize the spatial grid
        self.gridW = ceil(w / self.gridSize);
        self.gridH = ceil(h / self.gridSize);
        ds_grid_resize(self.grid, self.gridW, self.gridH);
        ds_grid_clear(self.grid, undefined);
        
        return self;
    } 
    
    /** Update */
    function __updateElemLayout(elem) {
        gml_pragma("forceinline");
        
        // Cache the nearest scrollable parent (if exists)
        if (!elem.isScrollbar) {
            var currentParent = elem.parent;
            while (currentParent != undefined) {
                if (currentParent.isScrollbar) {
                    currentParent = currentParent.parent;
                    continue;
                }
                
                if (currentParent.__UiScrollbar != undefined) {
                    elem.scrollableParent = currentParent;
                    break;
                }
            
                currentParent = currentParent.parent;
            }
        }
        
        // Store the layout position data of this element
        elem.layout = flexpanel_node_layout_get_position(elem.node, false);
        elem.width = elem.layout.width;
        elem.height = elem.layout.height;
        elem.x1 = elem.layout.left; 
        elem.y1 = elem.layout.top - (elem.scrollableParent ? elem.scrollableParent.scrollTop : 0);
        elem.x2 = elem.layout.left + elem.width; 
        elem.y2 = elem.y1 + elem.height;
        elem.xp1 = elem.x1 - elem.layout.paddingLeft;
        elem.yp1 = elem.y1 - elem.layout.paddingTop;
        elem.xp2 = elem.x2 + elem.layout.paddingRight;
        elem.yp2 = elem.y2 + elem.layout.paddingBottom;
        
        // Add the element to the spatial partition grid
        self.__addElemToGrid(elem);
        
        // Run the onMount method, if not yet executed for this element
        if (!elem.mounted) {
            elem.mounted = true;
            if (elem.onMount != undefined) elem.onMount();
        }
        
        // Run the update on the children
        var _children = elem.children;
        for (var i = elem.childrenLength - 1; i >= 0; i--) {
            self.__updateElemLayout(_children[i]);
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
            if (a.__drawIndex < b.__drawIndex) return -1;
            if (a.__drawIndex > b.__drawIndex) return 1;
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
            self.__updateElemLayout(self);
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
                    
                    if (_elem.handpoint && window_get_cursor() == cr_default && self.draggedElement == undefined) {
                        window_set_cursor(cr_handpoint);
                    }
                    
                    break;
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
         
                if (self.deepestTarget.draggable) {
                    self.potentialDraggedElement = self.deepestTarget;
                    self.potentialDraggedElement.dragStartX = self.mouseX;
                    self.potentialDraggedElement.dragStartY = self.mouseY;
                }
            }
        }
        
        // Handle mouse release
        if (self.mouseLeftReleased) {
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
                global.UI.dispatchEvent(UI_EVENT.click, self.deepestTarget);
            }
            
            global.UI_CLICK_START = undefined;
            self.potentialDraggedElement = undefined;
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
            gpu_set_scissor(elem.xp1, elem.yp1, elem.xp2 - elem.xp1, elem.yp2 - elem.yp1);
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
            self.needsRedraw = true;
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
    
    
    /** Spatial partition grid methods */
    function __addElemToGrid(elem) {
        if (self.gridW == 0 || self.gridH == 0) return;
        
        // Calculate grid bounds for this node
        var gridX1 = max(0, floor(elem.xp1 / self.gridSize));
        var gridY1 = max(0, floor(elem.yp1 / self.gridSize));
        var gridX2 = min(self.gridW - 1, floor(elem.xp2 / self.gridSize));
        var gridY2 = min(self.gridH - 1, floor(elem.yp2 / self.gridSize));
        
        // Store cells this node occupies
        for (var gx = gridX1; gx <= gridX2; gx++) {
            for (var gy = gridY1; gy <= gridY2; gy++) {
                
                var cells = ds_grid_get(self.grid, gx, gy);
                if (cells == undefined) {
                    cells = [];
                    ds_grid_set(self.grid, gx, gy, cells);
                }
                array_push(cells, elem);
            }
        }
    }
    
    setName("UniqueUI");
}

global.UI = new UiRoot();