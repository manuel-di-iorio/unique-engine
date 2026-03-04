/// @description Editor UI Assets - Now the "Scene" panel showing only scene hierarchy
/// Contains a scene selector dropdown and treeview for scene instances

function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", marginBottom: 62 }, { border: true });

    with (ui.Assets) {
      self.onDraw = method(self, function() {
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
            
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
            draw_text(self.x1 + 20, self.y1 + 8, "Scene");
        });
    }

    // Scene selector dropdown
    var _sceneDropdownItems = [];
    
    ui.Assets.SceneDropdown = new UiDropdown({
        position: "absolute",
        top: 2,
        right: 10,
        width: 150,
        height: 28,
    }, {
        name: "Assets.SceneDropdown",
        value: undefined,
        items: _sceneDropdownItems,
        label: "",
        onChange: method({ ui: ui }, function(val) {
            // When user picks a scene from dropdown, select it in the treeview
            if (val == undefined) return;
            var assetManager = global.editor.assetManager;
            var scenes = assetManager.getAssetsByType("Scene");
            for (var i = 0; i < array_length(scenes); i++) {
                if (scenes[i].uuid == val) {
                    var tvItem = scenes[i][$ "__treeviewItem"];
                    if (tvItem != undefined) {
                        tvItem.treeview.__onItemSelected(tvItem, true);
                    }
                    break;
                }
            }
        })
    });
    
    // Update dropdown items dynamically
    with (ui.Assets.SceneDropdown) {
        self.onStep(method(self, function() {
            // Rebuild scene list each frame (cheap since scenes are few)
            var assetManager = global.editor.assetManager;
            var scenes = assetManager.getAssetsByType("Scene");
            var newItems = [];
            for (var i = 0; i < array_length(scenes); i++) {
                array_push(newItems, { label: scenes[i].name, value: scenes[i].uuid });
            }
            self.items = newItems;
            
            // Sync dropdown value with active scene
            var activeScene = global.editor.editorManager.activeScene;
            if (activeScene != undefined) {
                self.value = activeScene.uuid;
            }
        }));
    }
    
    ui.Assets.add(ui.Assets.SceneDropdown);

    // Treeview
    ui.Assets.Treeview = new UiTreeview({ 
        flex: 1, 
        height: "85%", 
        flexDirection: "column",
    }, {
        dropzone: true
    });

    // Tools container
    ui.Assets.ToolsContainer = new UiNode({
      marginTop: 35,
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      padding: 5
    });

    with (ui.Assets.ToolsContainer) {
        function onDraw() {
            draw_set_color(global.UI_COL_INSPECTOR_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        }   
    }

    ui.Assets.add(ui.Assets.ToolsContainer);

    ui.Assets.ToolsContainer.Search = new UiTextbox({
        position: "relative",
        name: "Assets.ToolsContainer.Search",
        flex: 1,
        height: 24,
    }, {
        placeholder: "Filter assets...",
        onChange: method({ treeview: ui.Assets.Treeview }, function(val) {
             self.treeview.filter(val);
        }) 
    });
    ui.Assets.ToolsContainer.add(ui.Assets.ToolsContainer.Search);
  
    // Add X button to clear search
    ui.Assets.ToolsContainer.Search.ClearBtn = new UiButton(sprUiClose, {
      name: "Assets.ToolsContainer.Search.ClearBtn",
      position: "absolute",
      right: 0,
      top: 0,
      bottom: 0,
      width: 24,
    }, {
      outline: true,
      tooltip: "Clear the filtered assets list",
      enableRipple: false
    });
    
    ui.Assets.ToolsContainer.Search.add(ui.Assets.ToolsContainer.Search.ClearBtn);
    
    with (ui.Assets.ToolsContainer.Search.ClearBtn) {
        self.parentTextbox = ui.Assets.ToolsContainer.Search;
        
        // Control visibility based on text content
        self.onStep(method(self, function() {
            self.visible = (self.parentTextbox.value != "");
        }));
        
        // Handle click to clear text
        self.onClick(method(self, function() {
            self.parentTextbox.value = "";
            if (self.parentTextbox.onChange) self.parentTextbox.onChange("", self.parentTextbox);
        }));
    }

    ui.Assets.add(ui.Assets.Treeview);

    // "Collapse button"
    ui.Assets.ToolsContainer.CollapseBtn = new UiButton(sprUiCollapse, {
        name: "Assets.CollapseBtn",
        marginLeft: 15,
        padding: 12,
    }, {
        outline: true,
        tooltip: "Collapse all folders"
    });
    
    ui.Assets.ToolsContainer.add(ui.Assets.ToolsContainer.CollapseBtn);
    
    ui.Assets.ToolsContainer.CollapseBtn.onClick(method({ treeview: ui.Assets.Treeview }, function() {
        self.treeview.collapseAll();
    }));

    // "Add button" - Scene context: creates scene objects
    ui.Assets.ToolsContainer.AddBtn = new UiButton(sprUiCreateAsset, { 
        name: "Assets.AddBtn",
        marginLeft: 10,
        marginRight: 3,
        padding: 12,
    }, { 
        outline: true, 
        tooltip: "Add new scene object" 
    });
    
    ui.Assets.ToolsContainer.add(ui.Assets.ToolsContainer.AddBtn);

    // Connect Add button to context menu
    ui.Assets.ToolsContainer.AddBtn.onClick(method({ treeview: ui.Assets.Treeview }, function() {
        if (self.treeview.onContextMenu != undefined) {
            self.treeview.onContextMenu(undefined);
        }
        return true;
    }));

    
    /** Events */
    var Treeview = ui.Assets.Treeview;
    Treeview.Items.enableScrollbar();
        
    Treeview.onItemSelected = editorTreeviewOnItemSelected;
    Treeview.onMultiItemSelected = editorTreeviewOnMultiItemSelected;
    Treeview.onAssetDrop = editorTreeviewOnAssetDrop;
    Treeview.onRemoveItem = editorTreeviewOnRemoveAsset; 
    
    // Store reference for context menu
    var currentMenu = undefined;
    
    // Context menu handler - Scene-specific (scene objects, Object3D, etc.)
    Treeview.onContextMenu = method({ treeview: Treeview }, function(treeviewItem) {
        var items = [];
        
        if (treeviewItem == undefined) {
            // Background click - show "Add" menu for scene objects
            items = [
                { label: "New Scene", icon: sprUiScene, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Scene");
                })},
                { label: "New Object3D", icon: sprUiObject, onClick: method({ treeview: self.treeview }, function() {
                    editorTreeviewOnNewAsset(undefined, "Object3D");
                })}
            ];
        } else {
            // Item click - show item actions
            items = [];
            
            // Add creation actions based on item type
            if (treeviewItem.assetType == "Mesh" || treeviewItem.assetType == "Object3D" || treeviewItem.assetType == "Bone") {
                 array_push(items, { label: "New Object3D", icon: sprUiObject, onClick: method({ item: treeviewItem }, function() {
                     editorTreeviewOnNewAsset(self.item, "Object3D");
                 })});
                 array_push(items, { separator: true });
              } else if (treeviewItem.assetType == "Scene") {
                array_push(items, { label: "New Object3D", icon: sprUiObject, onClick: method({ item: treeviewItem }, function() {
                    editorTreeviewOnNewAsset(self.item, "Object3D");
                })});

                array_push(items, { separator: true });
            }
            
            // Duplicate action
            array_push(items, { label: "Duplicate", shortcut: "Ctrl+D", icon: sprUiDuplicate, onClick: method({ item: treeviewItem }, function() {
                 editorTreeviewOnDuplicateAsset(self.item);
            })});
            
            // Delete action
            array_push(items, { label: "Delete", shortcut: "Delete", icon: sprUiTrash, onClick: method({ item: treeviewItem }, function() {
                self.item.__removeItem();
            })});
        }
        
        var menu = new UiContextMenu(global.UI.mouseX, global.UI.mouseY, items);
        menu.show();
    });   
    
    
    // Handle right-click on treeview background
    ui.Assets.Treeview.onMouseUp(method({ Treeview }, function() {
        if (mouse_lastbutton == mb_right) {
            self.Treeview.onContextMenu(undefined);
            return true;
        }
    }));

    // Handle dropping assets on the treeview background (move to root)
    ui.Assets.Treeview.onDrop = method({ Treeview }, function(draggedContent) {
        var draggedItem = draggedContent.parent;
        // Pass self.Treeview as the target (representing the root)
        return editorTreeviewOnAssetDrop(draggedItem, self.Treeview);
    });
}
