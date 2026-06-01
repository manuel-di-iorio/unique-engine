/// @description Editor UI Assets - Now the "Scene" panel showing only scene hierarchy
/// Contains a scene selector dropdown and treeview for scene instances

function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ 
        name: "Assets", 
        minWidth: 300, 
        width: "20%", 
        marginBottom: 62,
        flexDirection: "column",
        // resizable: true,
        // resizableEdges: ["right"]
    }, { border: true });

    with (ui.Assets) {
      self.onDraw = method(self, function() {
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        });
    }

    // Header
    ui.Assets.Header = new UiNode({
        name: "Assets.Header",
        width: "100%",
        height: 36,
        flexDirection: "row",
        alignItems: "center",
        paddingVertical: 3,
        paddingBottom: 5
    });
    
    // Title
    ui.Assets.Header.Title = new UiText("Scene", { marginLeft: 15 }, { color: c_white, font: fText });
    ui.Assets.Header.add(ui.Assets.Header.Title);

    // Scene selector dropdown
    function __sceneDropdownItemsGetter(searchValue) {
        var assetManager = global.editor.assetManager;
        var scenes = assetManager.getAssetsByType("Scene");
        var items = [];
        for (var i = 0; i < array_length(scenes); i++) {
            array_push(items, { label: scenes[i].name, value: scenes[i].uuid });
        }
        return items;
    }
    
    ui.Assets.SceneDropdown = new UiDropdown({
        position: "relative",
        marginLeft: 20,
        marginRight: 5,
        flex: 1,
        height: 25,
    }, {
        name: "Assets.SceneDropdown",
        value: undefined,
        items: [], // Populated by itemsGetter
        itemsGetter: __sceneDropdownItemsGetter,
        onChange: method({ ui: ui }, function(val) {
            // When user picks a scene from dropdown, change the active scene
            if (val == undefined) return;
            var assetManager = global.editor.assetManager;
            var scenes = assetManager.getAssetsByType("Scene");
            for (var i = 0, il = array_length(scenes); i < il; i++) {
                if (scenes[i].uuid == val) {
                    global.editor.editorManager.setActiveAsset(scenes[i]);
                    break;
                }
            }
        })
    });
    
    // ui.Assets.Header.add(ui.Assets.SceneDropdown);
    // ui.Assets.add(ui.Assets.Header);
    
    // Update dropdown items dynamically
    // Track active scene to refresh treeview
    ui.Assets.lastActiveScene = undefined;
    
    ui.Assets.refreshTreeview = method(ui.Assets, function() {
        var activeScene = global.editor.editorManager.activeScene;
        self.Treeview.Items.destroyChildren(); // Properly destroy current items and their UI nodes
        if (self.Treeview.Items[$ "__UiScrollbar"] == undefined) {
            self.Treeview.Items.enableScrollbar();
        }
        
        if (activeScene != undefined) {
            // Build the hierarchy (instances) directly into the treeview root
            if (struct_exists(activeScene, "children")) {
                editorTreeviewUtil_createTreeviewItemsForChildren(activeScene, self.Treeview, sprUiObject);
            }
        }
        global.UI.requestUpdate();
        global.UI.requestRedraw();
    });

    // Sync Scene dropdown + treeview when active scene changes globally
    if (global.editor[$ "events"] != undefined) {
        global.editor.events.on("activeSceneChanged", method({ ui: ui }, function(ev) {
            var scene = ev.data[$ "scene"];
            self.ui.Assets.SceneDropdown.items = __sceneDropdownItemsGetter("");
            self.ui.Assets.SceneDropdown.value = (scene != undefined) ? scene.uuid : undefined;
            self.ui.Assets.lastActiveScene = scene;
            self.ui.Assets.refreshTreeview();
        }));
    }

    // Initial sync (in case a scene is already active when this UI is created)
    var __initScene = global.editor.editorManager.activeScene;
    if (__initScene != undefined) {
        ui.Assets.SceneDropdown.items = __sceneDropdownItemsGetter("");
        ui.Assets.SceneDropdown.value = __initScene.uuid;
        ui.Assets.lastActiveScene = __initScene;
        global.UI.requestRedraw();
    }

    // Treeview
    ui.Assets.Treeview = new UiTreeview({ 
        flex: 1, 
        marginTop: 6,
        marginBottom: 15,
        flexDirection: "column",
    }, {
        dropzone: true
    });

    // Tools container
    ui.Assets.ToolsContainer = new UiNode({
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

    // ui.Assets.add(ui.Assets.ToolsContainer);

    ui.Assets.ToolsContainer.Search = new UiTextbox({
        position: "relative",
        name: "Assets.ToolsContainer.Search",
        flex: 1,
        height: 24,
    }, {
        placeholder: "Filter instances...",
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
                { label: "New Object3D", icon: sprUiObject, onClick: method({ treeview: self.treeview }, function() {
                    var em = global.editor.editorManager;
                    var activeScene = (em != undefined) ? em.activeScene : undefined;
                    // Create instance under activeScene, but show it in the Assets panel treeview
                    editorTreeviewOnNewAsset(undefined, "Object3D", self.treeview, activeScene);
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
