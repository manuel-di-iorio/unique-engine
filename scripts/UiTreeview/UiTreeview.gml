function UiTreeview(style = {}, props = {}): UiNode(style, props) constructor {
    var _this = self;
    self.selected = [];
    
    // Create the items container
    self.Items = new UiNode({ padding: 5, paddingTop: 3 }, { hoverable: false });
    self.Items.draw = function(x1, y1, x2, y2, hovered, xp1, yp1, xp2, yp2) {
        draw_set_color(oSceneEditor.uiColBox);
        draw_line(x1-1, y1, x2, y1);
    }
    
    // Create the root folder items
    var _treeviewItemStyle = {
        flex: 1, 
        height: 20,
        marginBottom: 12, 
        padding: 5 
    };
    
    var _treeviewItemOnSelect = method(_this, function(item) {
        self.selected = [item];
        self.Items.traverseChildren(method({ item }, function(child) {
            child.isSelected = child == self.item;
        }))
    });
    
    self.Textures = new UiTreeviewItem(_treeviewItemStyle, {
        label: "Textures",
        type: "Folder",
        deletable: false,
        icon: sprUiTextures,
        onSelect: _treeviewItemOnSelect
    });
    
    self.Materials = new UiTreeviewItem(_treeviewItemStyle, {
        label: "Materials",
        type: "Folder",
        deletable: false,
        icon: sprUiMaterials,
        onSelect: _treeviewItemOnSelect
    });
    
    self.Objects = new UiTreeviewItem(_treeviewItemStyle, {
        label: "Objects",
        type: "Folder",
        deletable: false,
        icon: sprUiObjects,
        onSelect: _treeviewItemOnSelect
    });
    
    self.Scenes = new UiTreeviewItem(_treeviewItemStyle, {
        label: "Scenes",
        type: "Folder",
        deletable: false,
        icon: sprUiScenes,
        onSelect: _treeviewItemOnSelect
    });
       
    self.add(self.Items);
    self.Items.add(self.Textures, self.Materials, self.Objects, self.Scenes);
    
    function draw(x1, y1, x2, y2, hovered, xp1, yp1, xp2, yp2) {
        draw_set_color(oSceneEditor.uiColTreeBg);
        draw_rectangle(xp1, yp1, xp2, yp2, false);
    }
}