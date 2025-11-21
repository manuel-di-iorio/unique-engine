function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", marginBottom: 62 }, { border: true });
    ui.Assets.Treeview = new UiTreeview({ 
        marginTop: 35, 
        flex: 1, 
        height: "90%", 
        flexDirection: "column" 
    });
    
    ui.Assets.add(ui.Assets.Treeview);
    
    // Add button in header
    ui.Assets.AddBtn = new UiButton(sprUiCreateAsset, { 
        name: "Assets.AddBtn",
        position: "absolute",
        top: 5,
        right: 10,
        padding: 5,
        paddingBottom: 4,
        marginTop: 10,
        marginRight: 10
    }, { 
        outline: true, 
        tooltip: "Add new asset or folder" 
    });
    
    ui.Assets.add(ui.Assets.AddBtn);
        
    ui.Assets.onDraw = method(ui.Assets, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
        draw_text(self.x1 + 20, self.y1 + 8, "Assets");
    });
        
    /** Events */
    var Treeview = ui.Assets.Treeview;
    Treeview.enableScrollbar();
        
    Treeview.onItemSelected = editorTreeviewOnItemSelected;
    Treeview.onAssetDrop = editorTreeviewOnAssetDrop;
    Treeview.onRemoveItem = editorTreeviewOnRemoveAsset; 
    
    // Store reference for context menu
    var currentMenu = undefined;
    
    // Context menu handler
    Treeview.onContextMenu = method({ treeview: Treeview }, function(treeviewItem) {
        var items = [];
        
        if (treeviewItem == undefined) {
            // Background click - show "Add" menu
            items = [
                { label: "New folder", icon: sprUiFolder, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Folder");
                })},
                { separator: true },
                { label: "New texture", icon: sprUiTexture, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Texture");
                })},
                { label: "New material", icon: sprUiMaterial, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Material");
                })},
                { label: "New mesh", icon: sprUiObject, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Mesh");
                })},
                { label: "New scene", icon: sprUiScene, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Scene");
                })},
                { separator: true },
                { label: "Import model", icon: sprUiImportModel, onClick: function() {
                    editorTreeviewOnModelImport(undefined);
                }}
            ];
        } else {
            // Item click - show item actions
            items = [];
            
            // Add creation actions based on item type
            if (treeviewItem.assetType == "Mesh") {
                array_push(items, { label: "New mesh", icon: sprUiObject, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Mesh");
                })});
                array_push(items, { separator: true });
            } else if (treeviewItem.assetType == "Folder") {
                array_push(items, { label: "New folder", icon: sprUiFolder, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Folder");
                })});
                array_push(items, { separator: true });
                array_push(items, { label: "New texture", icon: sprUiTexture, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Texture");
                })});
                array_push(items, { label: "New material", icon: sprUiMaterial, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Material");
                })});
                array_push(items, { label: "New mesh", icon: sprUiObject, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Mesh");
                })});
                array_push(items, { label: "New scene", icon: sprUiScene, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Scene");
                })});
                array_push(items, { separator: true });
                array_push(items, { label: "Import model", icon: sprUiImportModel, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnModelImport(self.item);
                })});
                array_push(items, { separator: true });
            }
            
            // Delete action
            array_push(items, { label: "Delete asset", icon: sprUiTrash, onClick: method({ item: treeviewItem }, function() {
                self.item.__removeItem();
            })});
        }
        
        var menu = new UiContextMenu(global.UI.mouseX, global.UI.mouseY, items);
        menu.show();
    });
    
    // Connect Add button to context menu
    ui.Assets.AddBtn.onClick(method({ treeview: Treeview }, function() {
        if (self.treeview.onContextMenu != undefined) {
            self.treeview.onContextMenu(undefined);
        }
        return true;
    }));
    
    // Handle right-click on treeview background
    Treeview.onMouseUp(method({ Treeview }, function() {
        if (mouse_lastbutton == mb_right) {
            self.Treeview.onContextMenu(undefined);
            return true;
        }
    }));
}
