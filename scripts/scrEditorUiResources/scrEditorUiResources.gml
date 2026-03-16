/// @description Editor UI Resources - Creates the Resources panel for project assets (Textures, Materials, Prefabs, Folders)
/// Positioned below the Scene View in the center column.

function EditorUiResources(ui) constructor {
    self.ui = ui;

    // Create the Resources container node
    ui.Resources = new UiNode({
        name: "Resources",
        height: "35%",
        minHeight: 120,
        flexDirection: "column",
        // resizable: true,
        // resizableEdges: ["top"]
    }, { border: true });

    // Draw background and title
    with (ui.Resources) {
        self.onDraw = method(self, function () {
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);

            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
            draw_text(self.x1 + 20, self.y1 + 8, "Resources");
        });
    }

    // Treeview for resources
    ui.Resources.Treeview = new UiTreeview({
        flex: 1,
        flexDirection: "column",
    }, {
        dropzone: true
    });

    // Tools container (filter + buttons)
    ui.Resources.ToolsContainer = new UiNode({
        marginTop: 35,
        flexDirection: "row",
        justifyContent: "space-between",
        alignItems: "center",
        padding: 5
    });

    with (ui.Resources.ToolsContainer) {
        function onDraw() {
            draw_set_color(global.UI_COL_INSPECTOR_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        }
    }

    ui.Resources.add(ui.Resources.ToolsContainer);

    // Search/Filter textbox
    ui.Resources.ToolsContainer.Search = new UiTextbox({
        position: "relative",
        name: "Resources.ToolsContainer.Search",
        flex: 1,
        height: 24,
    }, {
        placeholder: "Filter resources...",
        onChange: method({ treeview: ui.Resources.Treeview }, function (val) {
            self.treeview.filter(val);
        })
    });
    ui.Resources.ToolsContainer.add(ui.Resources.ToolsContainer.Search);

    // Add X button to clear search
    ui.Resources.ToolsContainer.Search.ClearBtn = new UiButton(sprUiClose, {
        name: "Resources.ToolsContainer.Search.ClearBtn",
        position: "absolute",
        right: 0,
        top: 0,
        bottom: 0,
        width: 24,
    }, {
        outline: true,
        tooltip: "Clear the filtered resources list",
        enableRipple: false
    });

    ui.Resources.ToolsContainer.Search.add(ui.Resources.ToolsContainer.Search.ClearBtn);

    with (ui.Resources.ToolsContainer.Search.ClearBtn) {
        self.parentTextbox = ui.Resources.ToolsContainer.Search;

        // Control visibility based on text content
        self.onStep(method(self, function () {
            self.visible = (self.parentTextbox.value != "");
        }));

        // Handle click to clear text
        self.onClick(method(self, function () {
            self.parentTextbox.value = "";
            if (self.parentTextbox.onChange) self.parentTextbox.onChange("", self.parentTextbox);
        }));
    }

    ui.Resources.add(ui.Resources.Treeview);

    // "Collapse button"
    ui.Resources.ToolsContainer.CollapseBtn = new UiButton(sprUiCollapse, {
        name: "Resources.CollapseBtn",
        marginLeft: 15,
        padding: 12,
    }, {
        outline: true,
        tooltip: "Collapse all folders"
    });

    ui.Resources.ToolsContainer.add(ui.Resources.ToolsContainer.CollapseBtn);

    ui.Resources.ToolsContainer.CollapseBtn.onClick(method({ treeview: ui.Resources.Treeview }, function () {
        self.treeview.collapseAll();
    }));

    // "Import button"
    ui.Resources.ToolsContainer.ImportBtn = new UiButton(sprUiImportModel, {
        name: "Resources.ImportBtn",
        marginLeft: 10,
        padding: 12,
    }, {
        outline: true,
        tooltip: "Import model (textures, materials, meshes)"
    });

    ui.Resources.ToolsContainer.add(ui.Resources.ToolsContainer.ImportBtn);

    // Connect Import button to model import
    ui.Resources.ToolsContainer.ImportBtn.onClick(method({ treeview: ui.Resources.Treeview }, function () {
        editorTreeviewOnModelImport(undefined);
        return true;
    }));

    // "Add button"
    ui.Resources.ToolsContainer.AddBtn = new UiButton(sprUiCreateAsset, {
        name: "Resources.AddBtn",
        marginLeft: 10,
        marginRight: 3,
        padding: 12,
    }, {
        outline: true,
        tooltip: "Add new resource or folder"
    });

    ui.Resources.ToolsContainer.add(ui.Resources.ToolsContainer.AddBtn);

    // Connect Add button to context menu
    ui.Resources.ToolsContainer.AddBtn.onClick(method({ treeview: ui.Resources.Treeview }, function () {
        if (self.treeview.onContextMenu != undefined) {
            self.treeview.onContextMenu(undefined);
        }
        return true;
    }));


    /** Events */
    var Treeview = ui.Resources.Treeview;
    Treeview.Items.enableScrollbar();

    Treeview.onItemSelected = editorTreeviewOnItemSelected;
    Treeview.onMultiItemSelected = editorTreeviewOnMultiItemSelected;
    Treeview.onAssetDrop = editorTreeviewOnAssetDrop;
    Treeview.onRemoveItem = editorTreeviewOnRemoveAsset;

    // Store reference for context menu
    var currentMenu = undefined;

    // Context menu handler - Resources-specific (Textures, Materials, Folders, Prefabs)
    Treeview.onContextMenu = method({ treeview: Treeview }, function (treeviewItem) {
        var items = [];

        if (treeviewItem == undefined) {
            // Background click - show "Add" menu for resources
            items = [
                {
                    label: "New Folder", icon: sprUiFolder, onClick: method({ treeview: self.treeview }, function () {
                        editorTreeviewOnNewAsset(undefined, "Folder");
                    })
                },
                {
                    label: "New Object3D", icon: sprUiObject, onClick: method({ treeview: self.treeview }, function () {
                        editorTreeviewOnNewAsset(undefined, "Object3D");
                    })
                },

                {
                    label: "New Texture", icon: sprUiTexture, onClick: method({ treeview: self.treeview }, function () {
                        editorTreeviewOnNewAsset(undefined, "Texture");
                    })
                },
                {
                    label: "New Material", icon: sprUiMaterial, onClick: method({ treeview: self.treeview }, function () {
                        editorTreeviewOnNewAsset(undefined, "Material");
                    })
                },
                {
                    label: "New Scene", icon: sprUiScene, onClick: method({ treeview: self.treeview }, function () {
                        editorTreeviewOnNewAsset(undefined, "Scene");
                    })
                },
                { separator: true },
                {
                    label: "Import Model", icon: sprUiImportModel, onClick: function () {
                        editorTreeviewOnModelImport(undefined);
                    }
                }
            ];
        } else {
            // Item click - show item actions
            items = [];

            // Add creation actions based on item type
            if (treeviewItem.assetType == "Mesh" || treeviewItem.assetType == "Object3D" || treeviewItem.assetType == "Bone") {
                array_push(items, {
                    label: "New Object3D", icon: sprUiObject, onClick: method({ item: treeviewItem }, function () {
                        editorTreeviewOnNewAsset(self.item, "Object3D");
                    })
                });
                array_push(items, { separator: true });
            } else if (treeviewItem.assetType == "Folder") {
                array_push(items, {
                    label: "New Folder", icon: sprUiFolder, onClick: method({ item: treeviewItem }, function () {
                        editorTreeviewOnNewAsset(self.item, "Folder");
                    })
                });
                array_push(items, {
                    label: "New Texture", icon: sprUiTexture, onClick: method({ item: treeviewItem }, function () {
                        editorTreeviewOnNewAsset(self.item, "Texture");
                    })
                });
                array_push(items, {
                    label: "New Material", icon: sprUiMaterial, onClick: method({ item: treeviewItem }, function () {
                        editorTreeviewOnNewAsset(self.item, "Material");
                    })
                });
                array_push(items, {
                    label: "New Object3D", icon: sprUiObject, onClick: method({ item: treeviewItem }, function () {
                        editorTreeviewOnNewAsset(self.item, "Object3D");
                    })
                });
                array_push(items, { separator: true });
                array_push(items, {
                    label: "Import Model", icon: sprUiImportModel, onClick: method({ item: treeviewItem }, function () {
                        editorTreeviewOnModelImport(self.item);
                    })
                });
                array_push(items, { separator: true });
            }

            // Duplicate action
            array_push(items, {
                label: "Duplicate", shortcut: "Ctrl+D", icon: sprUiDuplicate, onClick: method({ item: treeviewItem }, function () {
                    editorTreeviewOnDuplicateAsset(self.item);
                })
            });

            // Delete action
            array_push(items, {
                label: "Delete", shortcut: "Delete", icon: sprUiTrash, onClick: method({ item: treeviewItem }, function () {
                    self.item.__removeItem();
                })
            });
        }

        var menu = new UiContextMenu(global.UI.mouseX, global.UI.mouseY, items);
        menu.show();
    });


    // Handle right-click on treeview background
    ui.Resources.Treeview.onMouseUp(method({ Treeview }, function () {
        if (mouse_lastbutton == mb_right) {
            self.Treeview.onContextMenu(undefined);
            return true;
        }
    }));

    // Handle dropping assets on the treeview background (move to root)
    ui.Resources.Treeview.onDrop = method({ Treeview }, function (draggedContent) {
        var draggedItem = draggedContent.parent;
        // Pass self.Treeview as the target (representing the root)
        return editorTreeviewOnAssetDrop(draggedItem, self.Treeview);
    });
}
