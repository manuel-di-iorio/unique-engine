/**
 * Treeview
 */
function UiTreeview(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiTreeview");
    var _this = self;
    self.selectedItem = undefined;  
    self.pointerEvents = true;
    self.onNewAsset = undefined;
    self.onRemoveItem = undefined;
    self.onItemSelected = undefined;
    self.onAssetDrop = undefined;
    
    // Create the items container
    self.Items = new UiNode({ name: "UiTreeview.Items", marginTop: 5, paddingBottom: 5 });
    self.add(self.Items);

    // Create the root folder items
    var rootAssetItemStyle = { name: "UiTreeview.Item", paddingVertical: 3 };
    
    self.Textures = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Textures",
        type: "folder",
        assetType: "texture",
        icon: sprUiTexture,
        entity: true
    });
    
    self.Materials = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Materials",
        type: "folder",
        assetType: "material",
        icon: sprUiMaterial,
        entity: true
    });
    
    self.Models = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Models",
        type: "folder",
        assetType: "model",
        icon: sprUiObject,
        entity: true
    });
    
    //self.Lights = new UiTreeviewItem(rootAssetItemStyle, {
        //treeview: _this,
        //name: "Lights",
        //type: "folder",
        //assetType: "light",
        //icon: sprUiLight,
        //entity: true
    //});
    //
    //self.Cameras = new UiTreeviewItem(rootAssetItemStyle, {
        //treeview: _this,
        //name: "Cameras",
        //type: "folder",
        //assetType: "camera",
        //icon: sprUiCamera,
        //entity: true
    //});
    
    self.Scenes = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Scenes",
        type: "folder",
        assetType: "scene",
        icon: sprUiScene,
        entity: true
    });
       
    self.Items.add(self.Textures, self.Materials, self.Models, /*self.Lights, self.Cameras,*/ self.Scenes);
    
    function __onItemSelected(treeviewItem) {
        if (self.selectedItem == treeviewItem) return;
        self.selectedItem = treeviewItem;
        self.Items.traverseChildren(method({ treeviewItem }, function(child) {
            child.selected = child == self.treeviewItem;
        }));
        if (self.onItemSelected != undefined) self.onItemSelected(treeviewItem);
    }
}

/**
 * Treeview Item
 */
function UiTreeviewItem(style = {}, props = {}): UiNode(style, props) constructor {
    var _this = self;
    self.treeview = props[$ "treeview"];
    self.assetType = props[$ "assetType"];
    self.type = props[$ "type"];
    self.icon = props[$ "icon"];
    self.name = props[$ "name"];
    self.selected = false;
    self.collapsed = props[$ "collapsed"] ?? true;
    self.entity = props[$ "entity"] ?? false;
    self.asset = undefined;
    
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
    
    with (self.Content) { 
        // If this is not the root treeview item, enable the dragging
        if (!self.parent.entity) {
            self.draggable = true;
            self.handpoint = true;
        }
        
        self.onMouseEnter(function() {
            global.UI.needsRedraw = true;
            
        });
        
        self.onMouseLeave(function() {
            global.UI.needsRedraw = true; 
        });
        
        self.onMouseDown(function() {
            if (self.parent.entity) return;
            self.parent.treeview.__onItemSelected(self.parent);
        });
        
        self.onDraw = function() {
            if (!self.parent.entity && self.hovered) {
                draw_set_color(global.UI_COL_BTN_HOVER);
                draw_rectangle(0, self.yp1 + 3, self.xp2-2, self.yp2, false);
            }
            
            if (self.parent.selected) {
                draw_set_color(global.UI_COL_SELECTED);
                draw_rectangle(0, self.yp1 + 3, self.xp2-2, self.yp2, false);
            }
            
            // Draw the icon
            var xx = self.x1 + 30;
            var meanY = ~~mean(self.y1, self.y2);
            if (self.parent.icon) {
                draw_sprite(self.parent.icon, 0, xx + 10, meanY);
                xx += 25;
            }
            
            // Draw the label
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_font(fText);
            draw_text(xx, meanY, self.parent.asset == undefined ? self.parent.name : self.parent.asset.name);
        };
        
        // Use the external onAssetDrop callback if available
        self.onDrop = function(draggedTreeviewItem) {
            var draggedItem = draggedTreeviewItem.parent; // Il TreeviewItem che stiamo trascinando
            var targetItem = self.parent; // Il TreeviewItem su cui stiamo droppando
            
            // Check if there's an external callback defined in the treeview
            if (targetItem.treeview.onAssetDrop != undefined) {
                return targetItem.treeview.onAssetDrop(draggedItem, targetItem);
            }
            
            return false;
        };
    }
    
    // Left and right content
    self.LeftContent = new UiNode({ name: "UiTreeview.Item.Content.LeftContent", flexDirection: "row", alignItems: "center"  });
    self.RightContent = new UiNode({ name: "UiTreeview.Item.Content.RightContent", flexDirection: "row", alignItems: "center"  });
    self.Content.add(LeftContent, RightContent);

    // Arrow
    self.Arrow = new UiButton(sprUiTreeviewArrowDown, { 
        name: "UiTreeview.Item.Content.ArrowBtn",
        padding: 4, marginLeft: 5, marginRight: 10, width: 14, height: 9,
    }, { outline: true, visible: false });
    
    self.Arrow.onClick(method(self, function() {
        if (self.collapsed) {
            self.expandItem();
        } else {
            self.collapseItem();
        }
    }));
    
    self.LeftContent.add(self.Arrow);
     
    
    // Import model button
    if (self.type == "folder" && self.assetType == "model") {
        self.ImportModelIcon = new UiButton(sprUiImportModel, { 
            name: "UiTreeview.Item.Content.ImportModelBtn", padding: 5, paddingBottom: 4, marginRight: 15 
        }, { outline: true, tooltip: "Import model from file" });
        self.ImportModelIcon.treeview = self.treeview;
        self.ImportModelIcon.onClick(method(_this, function() {
            //self.__importModel(
            show_message("@todo: Button to import models from file");
        }));
        
        self.RightContent.add(self.ImportModelIcon); 
    }
    
    // Delete button
    if (!self.entity) {
        self.DeleteIcon = new UiButton(sprUiTrash, { 
            name: "UiTreeview.Item.ContentDeleteBtn", padding: 5, paddingBottom: 4, marginRight: 15
        }, { outline: true, tooltip: "Delete this asset" });
        self.DeleteIcon.treeview = self.treeview;
        
        // Stop the propagation of the "mouse down" event
        self.DeleteIcon.onMouseDown(function() {  return true; });
        
        self.DeleteIcon.onClick(method(_this, function() {
            self.__removeItem();
            return true;
        }));
        
        self.RightContent.add(self.DeleteIcon); 
    }
    
    // Create button
    if (self.type == "folder" || self.assetType == "model") {
        self.CreateIcon = new UiButton(sprUiCreateAsset, { 
            name: "UiTreeview.Item.Content.CreateBtn", padding: 5, paddingBottom: 4, marginRight: 20
        }, { outline: true, tooltip: "Create a new asset" });
        self.CreateIcon.treeview = self.treeview;
        
        // Stop the propagation of the "mouse down" event
        self.CreateIcon.onMouseDown(function() {  return true; });
        
        self.CreateIcon.onClick(method(_this, function() {
            self.__addItem();
            return true;
        }));
        
        self.RightContent.add(self.CreateIcon); 
    }
    
    self.Items = new UiNode();
    
    self.add(self.Items);
    
    // Methods 
    function __addItem() {
        var child = new UiTreeviewItem({ name: "UiTreeview.Item", marginLeft: 15, paddingVertical: 2.5 }, {
            treeview: self.treeview,
            assetType: self.assetType,
            type: self.assetType,
        });
        
        self.Items.add(child);
        self.Arrow.visible = true;
        self.expandItem();
        
        if (self.treeview.onNewAsset != undefined) self.treeview.onNewAsset(child);
        
        self.treeview.__onItemSelected(child);
    }
    
    function __removeItem() {
        if (!show_question("Are you sure you want to delete this asset?")) return;

        var _isSelected = self.treeview.selectedItem == self;
        if (_isSelected) {
            self.treeview.selectedItem = undefined;
        }
        
        if (self.treeview.onRemoveItem != undefined) self.treeview.onRemoveItem(self, _isSelected);
        
        var _parent = self.parent;
        self.destroy();
        
        if (!_parent.count()) {
            _parent.parent.collapseItem();
            _parent.parent.Arrow.hide();
        }
    }
    
    function expandItem() {
        self.collapsed = false;
        self.Arrow.sprite = sprUiTreeviewArrowDown;
        self.Arrow.show();
        self.Items.show();
    }
    
    function collapseItem() {
        self.collapsed = true;
        self.Arrow.sprite = sprUiTreeviewArrowRight;
        self.Items.hide();
    }
    
    function onDraw() {
        // Draw the item background if not collapsed
        if (self.entity && !self.collapsed) {
            draw_set_color(global.UI_COL_TREE_BG);
            draw_rectangle(self.xp1, self.y1, self.xp2, self.y2, false);
        }
    } 
}
