/**
 * 
 */
function UiTreeview(style = {}, props = {}): UiNode(style, props) constructor {
    var _this = self;
    self.selectedItems = [];  
    self.pointerEvents = true;
    setName(style[$ "name"] ?? "UiTreeview");
    self.onNewAsset = undefined;
    self.onItemSelected = undefined;
    
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
        root: true
    });
    
    self.Materials = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Materials",
        type: "folder",
        assetType: "material",
        icon: sprUiMaterial,
        root: true
    });
    
    self.Models = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Models",
        type: "folder",
        assetType: "model",
        icon: sprUiObject,
        root: true
    });
    
    //self.Lights = new UiTreeviewItem(rootAssetItemStyle, {
        //treeview: _this,
        //name: "Lights",
        //type: "folder",
        //assetType: "light",
        //icon: sprUiLight,
        //root: true
    //});
    //
    //self.Cameras = new UiTreeviewItem(rootAssetItemStyle, {
        //treeview: _this,
        //name: "Cameras",
        //type: "folder",
        //assetType: "camera",
        //icon: sprUiCamera,
        //root: true
    //});
    
    self.Scenes = new UiTreeviewItem(rootAssetItemStyle, {
        treeview: _this,
        name: "Scenes",
        type: "folder",
        assetType: "scene",
        icon: sprUiScene,
        root: true
    });
       
    self.Items.add(self.Textures, self.Materials, self.Models, /*self.Lights, self.Cameras,*/ self.Scenes);
    
    function __onItemSelected(treeviewItem) {
        self.selectedItems = [treeviewItem];
        self.Items.traverseChildren(method({ treeviewItem }, function(child) {
            child.selected = child == self.treeviewItem;
        }));
        if (self.onItemSelected != undefined) self.onItemSelected(treeviewItem);
    }
}

/**
 * 
 */
function UiTreeviewItem(style = {}, props = {}): UiNode(style, props) constructor {
    var _this = self;
    self.treeview = props[$ "treeview"];
    self.name = props[$ "name"];
    self.assetType = props[$ "assetType"];
    self.type = props[$ "type"];
    self.icon = props[$ "icon"];
    self.selected = false;
    self.collapsed = props[$ "collapsed"] ?? true;
    self.root = props[$ "root"] ?? false;
    self.asset = undefined;
    
    // Content
    self.Content = new UiNode({ name: "UiTreeview.Item.Content", padding: 2, flexDirection: "row", justifyContent: "space-between", alignItems: "center" });
    self.Content.pointerEvents = true;
    
    self.Content.onMouseDown(function() {
        if (self.root) return;
        self.treeview.__onItemSelected(self);
    });
    
    self.Content.onDraw = method(self, function() {
        if (self.selected) {
            draw_set_color(global.UI_COL_SELECTED);
            draw_rectangle(0, self.yp1 + 3, self.xp2-2, self.yp1 + 24 + 6, false);
        }
    });
    
    self.add(self.Content);
    
    // Left and right content
    self.LeftContent = new UiNode({ name: "UiTreeview.Item.Content.LeftContent", flexDirection: "row", alignItems: "center"  });
    self.RightContent = new UiNode({ name: "UiTreeview.Item.Content.RightContent", flexDirection: "row", alignItems: "center"  });
    self.Content.add(LeftContent, RightContent);

    // Arrow
    self.Arrow = new UiButton(sprUiTreeviewArrowDown, { 
        name: "UiTreeview.Item.Content.ArrowBtn",
        padding: 4, marginLeft: 5, marginRight: 10, width: 14, height: 9,
    }, { outline: true, autoResize: false, visible: false });
    
    self.Arrow.onClick(method(self, function() {
        if (self.collapsed) {
            self.expandItem();
        } else {
            self.collapseItem();
        }
    }));
    
    self.LeftContent.add(self.Arrow);
    
    // Icon
    if (self.icon) {
        self.Icon = new UiSprite(self.icon, { name: "UiTreeview.Item.Content.Icon", marginRight: 5 });
        self.LeftContent.add(self.Icon);
    }
    
    // Name
    self.Name = new UiText(self.name);
    self.LeftContent.add(self.Name);
    
    // Import model button
    if (self.type == "folder" && self.assetType == "model") {
        self.ImportModelIcon = new UiButton(sprUiImportModel, { 
            name: "UiTreeview.Item.Content.ImportModelBtn", padding: 5, paddingBottom: 4, marginRight: 15 
        }, { outline: true, tooltip: "Import model from file" });
        self.ImportModelIcon.treeview = self.treeview;
        self.ImportModelIcon.onClick(method(_this, function() {
            //self.__importModel(
            show_message("@todo");
        }));
        
        self.RightContent.add(self.ImportModelIcon); 
    }
    
    // Create button
    if (self.type == "folder" || self.assetType == "model") {
        self.CreateIcon = new UiButton(sprUiCreateAsset, { 
            name: "UiTreeview.Item.Content.CreateBtn", padding: 5, paddingBottom: 4, marginRight: 20 
        }, { outline: true, tooltip: "Create a new asset" });
        self.CreateIcon.treeview = self.treeview;
        self.CreateIcon.onClick(method(_this, function() {
            self.__addItem();
        }));
        
        self.RightContent.add(self.CreateIcon); 
    }
    
    self.Items = new UiNode();
    self.add(self.Items);
    
     
    function __addItem() {
        var child = new UiTreeviewItem({ name: "UiTreeview.Item", marginLeft: 15, paddingVertical: 2.5 }, {
            treeview: self.treeview,
            assetType: self.assetType,
            type: self.assetType
        });
        
        self.Items.add(child);
        self.Arrow.visible = true;
        self.expandItem();
        
        if (self.treeview.onNewAsset != undefined) self.treeview.onNewAsset(child);
    }
    
    function expandItem() {
        self.collapsed = false;
        self.Arrow.sprite = sprUiTreeviewArrowDown;
        self.Items.show();
    }
    
    function collapseItem() {
        self.collapsed = true;
        self.Arrow.sprite = sprUiTreeviewArrowRight;
        self.Items.hide();
    }
    
    function onDraw() {
        // Draw the item background if not collapsed
        if (self.root && !self.collapsed) {
            draw_set_color(global.UI_COL_TREE_BG);
            draw_rectangle(self.xp1, self.y1, self.xp2, self.y2, false);
        }
    }
}