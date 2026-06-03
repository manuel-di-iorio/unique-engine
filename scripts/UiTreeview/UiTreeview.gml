/**
 * Treeview - Free-form hierarchical tree structure
 * Supports flexible asset organization with drag & drop
 * @note This component is opinionated and should be customized.
 */
function UiTreeview(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiTreeview");
    var _this = self;
    self.selectedItem = undefined;  
    self.pointerEvents = true;
    self.onItemSelected = undefined;
    self.onAssetDrop = undefined;
    self.onContextMenu = undefined; // Callback for showing context menu
    self.backgroundColor = global.UI_COL_BG_SIDEBAR;
    
    // Create the items container
    self.Items = new UiNode({ name: "UiTreeview.Items", width: "100%" });
    self.add(self.Items);
    
    self.enableScrollbar(global.UI_COL_PRIMARY);
    
    // Handle delete shortcut
    self.onStep(method(self, function() {
        if (keyboard_check_pressed(vk_delete)) {
            if (self.selectedItem != undefined && !global.UI.hasAnyFocus()) {
                self.selectedItem.destroy();
                self.selectedItem = undefined;
            }
        }
    }));
    
    /**
     * Select a treeview item
     */
    function __onItemSelected(treeviewItem, focus = false) {
        if (self.selectedItem != treeviewItem) {
            if (self.selectedItem != undefined) self.selectedItem.selected = false;
            self.selectedItem = treeviewItem;
            self.selectedItem.selected = true;
            global.UI.requestRedraw();
        }
        
        if (self.onItemSelected != undefined) self.onItemSelected(treeviewItem, focus);
    }
    
    /**
     * Filter the treeview items by name
     */
    function filter(searchText) {
        var _lowerSearch = string_lower(searchText);
        
        var _filterItem = undefined;
        _filterItem = method({ _lowerSearch, _filterItem: function(item) {
                var nameToCheck = item.name;
                var matches = (_lowerSearch == "" || string_pos(_lowerSearch, string_lower(nameToCheck)) > 0);
                
                var hasMatchingChildren = false;
                var itemsNode = item[$ "Items"];
                if (itemsNode != undefined) {
                    var children = itemsNode.children;
                    for (var i = 0; i < array_length(children); i++) {
                        if (self._filterItem(children[i])) hasMatchingChildren = true;
                    }
                }
                
                var shouldBeVisible = matches || hasMatchingChildren;
                if (shouldBeVisible) {
                    item.show();
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
        
        var rootItems = self.Items.children;
        for (var i = 0; i < array_length(rootItems); i++) {
            _filterItem(rootItems[i]);
        }
    }

    /**
     * Validate if an item can be dropped onto another
     */
    function validateDrop(dragged, target) {
        if (dragged == target) return false;
        if (dragged.assetType == "Texture" || dragged.assetType == "Material") return false;
        if (target.assetType != "Folder") return false;
        return true;
    }

    /**
     * Collapse all items in the tree
     */
    function collapseAll() {
        self.Items.traverseChildren(function(child) {
            if (child[$ "isTreeviewItem"]) {
                child.collapseItem();
            }
        });
    }
}

/**
 * Treeview Item - Represents an item in the tree hierarchy
 */
function UiTreeviewItem(style = {}, props = {}): UiNode(style, props) constructor {
    if (style[$ "width"] == undefined) style.width = "100%";
    var _this = self;
    self.isTreeviewItem = true;
    self.treeview = props[$ "treeview"];
    self.assetType = props[$ "assetType"] ?? "Asset";
    self.icon = props[$ "icon"];
    self.name = props[$ "name"] ?? style[$ "name"] ?? "Item";
    self.asset = props[$ "asset"];
    self.selected = false;
    self.collapsed = props[$ "collapsed"] ?? true;
    self.depth = props[$ "depth"] ?? 0;
    
    // Row Content
    self.Content = new UiNode({ 
        name: "UiTreeview.Item.Content", 
        width: "100%",
        height: 32, 
        flexDirection: "row",
        alignItems: "center",
        paddingLeft: 4 + self.depth * 16,
        paddingRight: 4
    }, {
        pointerEvents: true,
        handpoint: true,
        draggable: props[$ "draggable"] ?? true,
        dropzone: props[$ "dropzone"] ?? true
    });
    self.add(self.Content);
    
    var _item = self;
    var _content = self.Content;
    
    // Background highlight
    self.Content.onDraw = method({ Content: _content, Item: _item }, function() {
        if (self.Content.hovered || self.Item.selected) {
            draw_set_color(self.Item.selected ? global.UI_COL_PRIMARY : global.UI_COL_BTN_HOVER);
            draw_set_alpha(self.Item.selected ? 0.3 : 0.1);
            draw_rectangle(self.Content.x1, self.Content.y1, self.Content.x2, self.Content.y2, false);
            draw_set_alpha(1);
        }
    });

    // Arrow Button (Toggle)
    self.ArrowContainer = new UiNode({ width: 20, height: 20, justifyContent: "center", alignItems: "center" });
    self.Content.add(self.ArrowContainer);
    
    self.Arrow = new UiNode({ width: 12, height: 12 }, { pointerEvents: true });
    var _arrow = self.Arrow;
    
    self.Arrow.onDraw = method({ Arrow: _arrow, Item: _item }, function() {
        if (self.Item.assetType != "Folder") return;
        draw_set_color(self.Item.selected ? global.UI_COL_TEXT_MAIN : global.UI_COL_TEXT_DIM);
        var mx = (self.Arrow.x1 + self.Arrow.x2) / 2;
        var my = (self.Arrow.y1 + self.Arrow.y2) / 2;
        if (self.Item.collapsed) {
            draw_triangle(mx-3, my-4, mx-3, my+4, mx+3, my, false);
        } else {
            draw_triangle(mx-4, my-3, mx+4, my-3, mx, my+3, false);
        }
    });
    self.Arrow.onClick(method(self, function() {
        if (self.collapsed) self.expandItem(); else self.collapseItem();
    }));
    self.ArrowContainer.add(self.Arrow);

    // Icon
    self.Icon = new UiNode({ width: 20, height: 20, marginLeft: 4, marginRight: 8 });
    var _icon = self.Icon;
    
    self.Icon.onDraw = method({ Icon: _icon, Item: _item }, function() {
        var mx = (self.Icon.x1 + self.Icon.x2) / 2;
        var my = (self.Icon.y1 + self.Icon.y2) / 2;
        
        if (self.Item.icon != undefined && self.Item.icon != -1) {
            var _sw = sprite_get_width(self.Item.icon);
            var _sh = sprite_get_height(self.Item.icon);
            var _scale = min(16 / _sw, 16 / _sh);
            var _ox = sprite_get_xoffset(self.Item.icon);
            var _oy = sprite_get_yoffset(self.Item.icon);
            // Draw centered regardless of origin
            var _iconCol = self.Item.selected ? global.UI_COL_TEXT_MAIN : global.UI_COL_TEXT_DIM;
            draw_sprite_ext(self.Item.icon, 0, mx - (_sw/2 - _ox) * _scale, my - (_sh/2 - _oy) * _scale, _scale, _scale, 0, _iconCol, 1);
        } else {
            if (self.Item.assetType == "Folder") {
                draw_set_color(self.Item.collapsed ? #F59E0B : #FCD34D);
                // Folder shape
                draw_rectangle(self.Icon.x1+2, self.Icon.y1+6, self.Icon.x2-2, self.Icon.y2-4, false);
                draw_rectangle(self.Icon.x1+2, self.Icon.y1+4, self.Icon.x1+10, self.Icon.y1+6, false);
            } else {
                draw_set_color(#6366F1);
                draw_rectangle(self.Icon.x1+4, self.Icon.y1+4, self.Icon.x2-4, self.Icon.y2-4, false);
            }
        }
    });
    self.Content.add(self.Icon);

    // Label
    self.Label = new UiText(self.name, { flex: 1 }, { color: function() { return global.UI_COL_TEXT_MAIN; }, font: fTextSmall });
    self.Content.add(self.Label);

    // Handle selection
    self.Content.onMouseDown(method(self, function() {
        self.treeview.__onItemSelected(self);
    }));
    
    self.Content.onDoubleClick(method(self, function() {
        if (self.assetType == "Folder") {
            if (self.collapsed) self.expandItem(); else self.collapseItem();
        }
    }));

    // Context Menu
    self.Content.onContextMenu(method(self, function() {
        if (self.treeview.onContextMenu != undefined) {
            self.treeview.onContextMenu(self);
        }
    }));

    // Drag & Drop Callbacks
    self.canDrag = props[$ "canDrag"] ?? function() { return true; };
    self.canDrop = props[$ "canDrop"] ?? function(draggedItem) { 
        return self.assetType == "Folder" && draggedItem != self; 
    };

    self.Content.onDragStart = method(self, function() {
        if (!self.canDrag()) return false;
        self.dragging = true;
        return true;
    });

    self.Content.onDrop = method(self, function(draggedNode) {
        var draggedItem = draggedNode.parent; // Content's parent is the TreeviewItem
        if (self.canDrop(draggedItem)) {
            if (self.treeview.onAssetDrop != undefined) {
                self.treeview.onAssetDrop(draggedItem, self);
            }
            return true;
        }
        return false;
    });

    // Children Container
    self.Items = new UiNode({});
    if (self.collapsed) self.Items.hide();
    self.add(self.Items);
    
    function expandItem() {
        self.collapsed = false;
        self.Items.show();
        global.UI.requestUpdate();
    }
    
    function collapseItem() {
        self.collapsed = true;
        self.Items.hide();
        global.UI.requestUpdate();
    }

    /**
     * Set the depth of this item and its children
     */
    function __setDepth(depth) {
        self.depth = depth;
        var _pLeft = 4 + self.depth * 16;
        flexpanel_node_style_set_padding(self.Content.node, flexpanel_edge.left, _pLeft);
        self.Content.layout.paddingLeft = _pLeft;
        
        var _children = self.Items.children;
        for (var i = 0; i < array_length(_children); i++) {
            var _child = _children[i];
            if (_child[$ "isTreeviewItem"]) {
                _child.__setDepth(depth + 1);
            }
        }
    }
    
    function addChild(childItem) {
        if (childItem[$ "__setDepth"] != undefined) {
            childItem.__setDepth(self.depth + 1);
        }
        self.Items.add(childItem);
        self.__updateArrowVisibility();
        return self;
    }

    /**
     * Update arrow visibility based on children
     */
    function __updateArrowVisibility() {
        self.Arrow.visible = (self.Items.childrenLength > 0);
        return self;
    }

    self.__updateArrowVisibility();
}
