/**
 * Treeview - Free-form hierarchical tree structure
 * Supports flexible asset organization with drag & drop
 */
function UiTreeview(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiTreeview");
    var _this = self;
    self.selectedItem = undefined;  
    self.pointerEvents = true;
    self.onItemSelected = undefined;
    self.onAssetDrop = undefined;
    self.onContextMenu = undefined; // Callback for showing context menu
    
    // Create the items container
    self.Items = new UiNode({ name: "UiTreeview.Items", marginTop: 5, paddingBottom: 5, flex: 1, width: "100%" });
    self.add(self.Items);
    
    // Handle delete shortcut
    self.onStep(method(self, function() {
        if (keyboard_check_pressed(vk_delete)) {
            if (self.selectedItem != undefined && !global.UI.hasAnyFocus()) {
                self.selectedItem.__removeItem();
            }
        }
    }));
    
    /**
     * Select a treeview item
     */
    function __onItemSelected(treeviewItem, focus = false) {
        if (self.selectedItem == treeviewItem) return;
        self.selectedItem = treeviewItem;
        self.Items.traverseChildren(method({ treeviewItem }, function(child) {
            child.selected = child == self.treeviewItem;
        }));
        if (self.onItemSelected != undefined) self.onItemSelected(treeviewItem, focus);
    }
    
    /**
     * Validate if an asset can be dropped on a target
     * @param {Struct} draggedItem - The treeview item being dragged
     * @param {Struct} targetItem - The target treeview item
     * @return {Bool} True if the drop is valid
     */
    function validateDrop(draggedItem, targetItem) {
        var draggedType = draggedItem.assetType;
        var targetType = targetItem.assetType;
        
        // Cannot drop on itself
        if (draggedItem == targetItem) return false;
        
        // Textures and Materials cannot be moved
        if (draggedType == "Texture" || draggedType == "Material") {
            return false;
        }
        
        // Check if target accepts this type
        if (targetItem[$ "acceptsDropOf"] != undefined) {
            var accepts = targetItem.acceptsDropOf;
            var found = false;
            for (var i = 0; i < array_length(accepts); i++) {
                if (accepts[i] == draggedType) {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }
        
        // Folders can accept anything
        if (targetType == "Folder") return true;
        
        // Models and Object3D can be dropped on other models, scenes or Object3D
        if (draggedType == "Mesh" || draggedType == "Object3D" || draggedType == "Bone") {
            if (targetType == "Mesh" || targetType == "Scene" || targetType == "Object3D" || targetType == "Bone") {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Filter the treeview items by name
     * @param {String} searchText - The text to filter by
     */
    function filter(searchText) {
        var _lowerSearch = string_lower(searchText);
        
        // Internal recursive function
        var _filterItem = undefined;
        _filterItem = method({ _lowerSearch, _filterItem:  function(item) {
                // Check if this item matches
                var nameToCheck = "";
                if (item[$ "asset"] != undefined) {
                    nameToCheck = item.asset[$ "name"] ?? "";
                } else {
                    nameToCheck = item[$ "name"] ?? "";
                }
                var matches = (_lowerSearch == "" || (nameToCheck != "" && string_pos(_lowerSearch, string_lower(nameToCheck)) > 0));
                
                var hasMatchingChildren = false;
                
                // Check children items
                var itemsNode = item[$ "Items"];
                if (itemsNode != undefined && itemsNode[$ "children"] != undefined) {
                    var children = itemsNode.children;
                    for (var i = 0; i < array_length(children); i++) {
                        var child = children[i];
                        // Recursively check child
                        if (self._filterItem(child)) {
                            hasMatchingChildren = true;
                        }
                    }
                }
                
                var shouldBeVisible = matches || hasMatchingChildren;
                
                if (shouldBeVisible) {
                    item.show();
                    // If we have matching children and there is a search term, expand to show them
                    if (hasMatchingChildren && _lowerSearch != "") {
                        if (item.collapsed) item.expandItem();
                    }
                } else {
                    item.hide();
                }
                
                return shouldBeVisible;
            } 
        }, function(item) {
            return _filterItem(item);
        });
        
        // Apply to root items
        if (self.Items.children != undefined) {
            var rootItems = self.Items.children;
            for (var i = 0; i < array_length(rootItems); i++) {
                _filterItem(rootItems[i]);
            }
        }
    }

    /**
     * Recursively collapse all items
     */
    function collapseAll() {
        var context = {
            run: function(item) {
                if (item.isScrollbar) return;
                
                 // Collapse self
                if (item[$ "collapseItem"] != undefined) {
                    item.collapseItem();
                }
                
                // Recurse children
                var itemsNode = item[$ "Items"];
                if (itemsNode != undefined && itemsNode[$ "children"] != undefined) {
                    var children = itemsNode.children;
                    for (var i = 0; i < array_length(children); i++) {
                        self.run(children[i]);
                    }
                }
            }
        };
        
        var _recursiveCollapse = method(context, context.run);
        
        // Apply to root items
        if (self.Items.children != undefined) {
            var rootItems = self.Items.children;
            for (var i = 0; i < array_length(rootItems); i++) {
                _recursiveCollapse(rootItems[i]);
            }
        }
    }
}

/**
 * Treeview Item - Represents an item in the tree hierarchy
 * Supports both category folders and individual assets
 */
function UiTreeviewItem(style = {}, props = {}): UiNode(style, props) constructor {
    var _this = self;
    self.treeview = props[$ "treeview"];
    self.assetType = props[$ "assetType"];
    self.type = props[$ "type"];
    self.icon = props[$ "icon"];
    self.name = props[$ "name"] ?? style[$ "name"] ?? "UiTreeview.Item";
    self.selected = false;
    self.collapsed = props[$ "collapsed"] ?? true;
    self.asset = props[$ "asset"] ?? undefined;
    self.acceptsDropOf = props[$ "acceptsDropOf"] ?? undefined;
    self.lastClickTime = -1;
    self.doubleClickThreshold = 300;
    
    // Store back-reference in asset for efficient lookup
    if (self.asset != undefined) {
        self.asset.__treeviewItem = self;
    }
    
    // Content
    self.Content = new UiNode({ 
        name: "UiTreeview.Item.Content", 
        padding: 2, 
        height: 30, 
        flexDirection: "row",
        justifyContent: "space-between",
        alignItems: "center",
    }, {
        pointerEvents: true,
        dropzone: true,
    });
    
    self.add(self.Content);
    
    // Store reference for use in callbacks
    var treeviewItem = _this;
    
    with (self.Content) {
        var contentNode = self;  // Capture the Content node reference
        
        // If this is not the root treeview item, enable the dragging
        self.draggable = true;
        self.handpoint = true;
        
        self.onMouseEnter(function() {
            global.UI.requestRedraw();
        });
        
        self.onMouseLeave(function() {
            global.UI.requestRedraw(); 
        });
        
        self.onMouseDown(method({ item: treeviewItem }, function() {
            // Only select on left click, not right click (right click is for context menu)
            if (mouse_lastbutton == mb_left) {
                var now = current_time;
                var isDoubleClick = (item.lastClickTime != -1 && now - item.lastClickTime <= item.doubleClickThreshold);
                
                item.treeview.__onItemSelected(item, isDoubleClick);
                item.lastClickTime = now;
            }
            return false;
        }));
        
        // Right click - context menu
        self.onMouseUp(method({ item: treeviewItem }, function() {
            if (mouse_lastbutton == mb_right) {
                if (item.treeview.onContextMenu != undefined) {
                    item.treeview.onContextMenu(item);
                    return true;
                }
            }
            return false;
        }));
        
        self.onDraw = method({ item: treeviewItem, node: contentNode }, function() {
            if (node.hovered) {
                draw_set_color(global.UI_COL_BTN_HOVER);
                draw_rectangle(0, node.y1 + 3, node.x2-2, node.y2 - 1, false);
            }
            
            if (item.selected) {
                draw_set_color(global.UI_COL_SELECTED);
                draw_rectangle(0, node.y1 + 3, node.x2-2, node.y2 - 1, false);
            }
            
            // Draw the icon
            var xx = node.x1 + 30;
            var meanY = (node.y1 + node.y2) / 2;
            
            var iconToDraw = item.icon;
            if (item.assetType == "Folder" && item.collapsed) {
                iconToDraw = sprUiFolderCollapsed;
            }
            
            if (iconToDraw) {
                draw_sprite(iconToDraw, 0, xx + 10, meanY);
                xx += 25;
            }
            
            // Draw the label
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_font(fText);
            var labelText = "";
            if (item[$ "asset"] != undefined) {
                labelText = item.asset[$ "name"] ?? "Unnamed Asset";
            } else {
                labelText = item[$ "name"] ?? "Unnamed Item";
            }
            draw_text(xx, meanY, labelText);
        });
        
        // Use the external onAssetDrop callback if available
        self.onDrop = method({ item: treeviewItem }, function(draggedTreeviewItem) {
            var draggedItem = draggedTreeviewItem.parent; // The TreeviewItem being dragged
            var targetItem = item; // The TreeviewItem being dropped onto
            
            // Check if there's an external callback defined in the treeview
            if (targetItem.treeview.onAssetDrop != undefined) {
                return targetItem.treeview.onAssetDrop(draggedItem, targetItem);
            }
            
            return false;
        });
    }
    
    // Left and right content
    self.LeftContent = new UiNode({ 
      name: "UiTreeview.Item.Content.LeftContent", 
      flexDirection: "row", 
      alignItems: "center",
      width: 20,
      height: 20,
    });
    self.Content.add(self.LeftContent);

    // Arrow
    self.Arrow = new UiSprite(self.collapsed ? sprUiTreeviewArrowRight : sprUiTreeviewArrowDown, { 
      name: "UiTreeview.Item.Content.ArrowBtn",
      marginLeft: 5, 
      marginRight: 10,
      width: 20,
      height: 20,
    }, { outline: true, visible: false, pointerEvents: true });
    
    self.Arrow.onClick(method(self, function() {
        if (self.collapsed) {
            self.expandItem();
        } else {
            self.collapseItem();
        }
    }));
    
    // Stop propagation on mousedown so clicking the arrow doesn't trigger 
    // selection/expansion on the parent Content node
    self.Arrow.onMouseDown(function() {
        return true; 
    });
    
    self.LeftContent.add(self.Arrow);
    
    self.Items = new UiNode({ marginLeft: 15 });
    if (self.collapsed) self.Items.hide();
    self.add(self.Items);
    
    // Methods 
    function __addItem() {
        var child = new UiTreeviewItem({ name: "UiTreeview.Item", marginLeft: 15 }, {
            treeview: self.treeview,
            assetType: self.assetType,
            type: self.assetType,
        });
        
        self.addChild(child);
        
        if (self.treeview.onNewAsset != undefined) self.treeview.onNewAsset(child);
        
        self.treeview.__onItemSelected(child);
    }
    
    function addChild(childItem, expand = true) {
        self.Items.add(childItem);
        self.__updateArrowVisibility();
        
        if (expand) {
            self.expandItem();
        }
    }
    
    function removeChild(childItem) {
        if (childItem.parent != undefined) {
            childItem.parent.remove(childItem);
        }
        self.__updateArrowVisibility();
    }
    
    function __updateArrowVisibility() {
        var hasChildren = self.Items.count() > 0;
        self.Arrow.visible = hasChildren;
        
        if (!hasChildren && !self.collapsed) {
            self.collapseItem();
        }
    }
    
    function moveItemTo(targetParent, shouldExpand = true) {
        // Save reference to the old parent before removing
        var oldParent = undefined;
        if (self.parent != undefined && self.parent.parent != undefined) {
            oldParent = self.parent.parent;
        }
        
        // Remember if this item was selected before moving
        var wasSelected = (self.treeview.selectedItem == self);
        
        // If selected, deselect it first to clean up any gizmos/helpers
        if (wasSelected) {
            oSceneEditor.editorManager.clearActiveAsset(true); // Keep scene active
        }
        
        // Remove from current parent
        if (self.parent != undefined) {
            self.parent.remove(self);
        }
        
        // Update the old parent (only if it's a real TreeviewItem)
        if (oldParent != undefined && oldParent[$ "__updateArrowVisibility"]) {
            oldParent.__updateArrowVisibility();
        }
        
        // Add to the new parent
        targetParent.Items.add(self);
        
        // Update the new parent (only if it's a real TreeviewItem)
        if (targetParent[$ "__updateArrowVisibility"]) {
            targetParent.__updateArrowVisibility();
        }
        if (shouldExpand && targetParent[$ "collapsed"] != undefined && targetParent.collapsed) {
            targetParent.expandItem();
        }
        
        // Restore selection if it was selected before
        if (wasSelected) {
            self.treeview.__onItemSelected(self);
        }
    }
    
    function __removeItem() {
        if (!show_question("Are you sure you want to delete this asset?")) return;
       
        var _isSelected = self.treeview.selectedItem == self;
        if (_isSelected) {
            self.treeview.selectedItem = undefined;
        }
        
        if (self.treeview != undefined && self.treeview[$ "onRemoveItem"] != undefined) {
            self.treeview.onRemoveItem(self, _isSelected);
        }
        
        var _parent = self.parent;
        self.destroy();
        
        if (_parent != undefined && _parent.parent != undefined) {
            var parentItem = _parent.parent;
            if (variable_struct_exists(parentItem, "__updateArrowVisibility")) {
                parentItem.__updateArrowVisibility();
            }
        }
    }
    
    function expandItem() {
        if (!self.collapsed) return;
        self.collapsed = false;
        self.Arrow.sprite = sprUiTreeviewArrowDown;
        self.Arrow.show();
        self.Items.show();
        
        // Trigger onExpand callback if defined
        if (self.treeview[$ "onExpand"] != undefined) {
            self.treeview.onExpand(self);
        }
        
        // Temporarily hide children to prevent visual glitch
        // They will be shown once the layout is updated
        self.Items.visible = false;
        
        // Show children after layout update
        var _items = self.Items;
        var _hasRun = { value: false }; // Use object to pass by reference
        _items.onStep(method({ items: _items, hasRun: _hasRun }, function(layoutUpdated) {
            if (layoutUpdated && !hasRun.value) {
                hasRun.value = true;
                items.visible = true;
                
                // Request another update so the now-visible items are added to the spatial tree
                global.UI.requestUpdate();
                
                // Defer removal to next frame to avoid modifying array during iteration
                runLater(method(items, function() {
                    __removeStepHandler();
                }));
            }
        }));
    }
    
    function collapseItem() {
        if (self.collapsed) return;
        self.collapsed = true;
        self.Arrow.sprite = sprUiTreeviewArrowRight;
        self.Items.hide();
        
        // Trigger onCollapse callback if defined
        if (self.treeview[$ "onCollapse"] != undefined) {
            self.treeview.onCollapse(self);
        }
    }
    
    function onDraw() {
        // Draw the item background if not collapsed
        if (!self.collapsed) {
            draw_set_color(global.UI_COL_TREE_BG);
            draw_rectangle(self.xp1, self.y1, self.xp2, self.y2, false);
        }
    }
}

