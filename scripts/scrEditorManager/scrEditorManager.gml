/// @description Editor Manager - Manages editor state including selection, tools, and UI references
/// This manages the state of the editor including active assets, tools, and UI state

function EditorManager() constructor {
    // Active state
    self.activeAsset = undefined;      // Currently selected asset in the treeview
    self.activeScene = undefined;       // Currently active scene being edited
    self.activeSceneTreeviewItem = undefined; // Reference to the treeview item of the active scene
    self.activeTool = "view";          // Current tool mode: "view", "move", "rotate", "scale"
    
    // UI References
    self.inspector = undefined;
    self.treeview = undefined;
    
    // Selection state
    self.selectedTreeviewItem = undefined;

    // Pick system
    self.pickLastHits = [];
    self.pickLastIndex = 0;
    self.pickLastPos = undefined;
    
    self.gizmoTarget = undefined; // Store the target for the gizmo (The ORIGINAL asset)
    self.renderClone = undefined; // The root clone being rendered

    /**
     * Set the currently active asset
     * @param {Struct} asset - The asset to set as active
     * @param {Struct} treeviewItem - Optional treeview item reference
     * @param {Struct} gizmoTarget - Optional target for transform controls (used for instances in scenes)
     */
    function setActiveAsset(asset, treeviewItem = undefined, gizmoTarget = undefined) {
        var sm = oSceneEditor.sceneManager;
        
        var assetChanged = self.activeAsset != asset;
        
        // Determine the effective gizmo target (defaults to asset if not provided)
        var newGizmoTarget = gizmoTarget != undefined ? gizmoTarget : asset;
        var gizmoTargetChanged = self.gizmoTarget != newGizmoTarget;
        
        // If neither the asset nor the gizmo target have changed, exit
        if (!assetChanged && !gizmoTargetChanged) return;

        // --- NEW: Scene Management Logic ---
        var oldScene = self.activeScene;
        var oldSceneItem = self.activeSceneTreeviewItem;
        
        var currentScene = undefined;
        var currentSceneItem = undefined;

        if (asset != undefined) {
            // Find parent scene via treeview (recursive search)
            var it = treeviewItem;
            while (it != undefined) {
                var itAsset = it[$ "asset"];
                if (itAsset != undefined && itAsset.type == "Scene") {
                    currentScene = itAsset;
                    currentSceneItem = it;
                    break;
                }
                
                // Navigate up: Child Item -> Items Node -> Parent Item
                var itParentItems = it[$ "parent"];
                if (itParentItems != undefined) {
                    var itParentItem = itParentItems[$ "parent"];
                    if (itParentItem != undefined) {
                        it = itParentItem;
                        continue;
                    }
                }
                it = undefined;
            }
        }

        // Update active scene identity ONLY if we found a new scene
        if (currentScene != undefined) {
            self.activeScene = currentScene;
            self.activeSceneTreeviewItem = currentSceneItem;

            // Collapse previous scene if we switched to a different scene
            if (oldScene != undefined && oldScene != currentScene) {
                if (oldSceneItem != undefined) {
                  oldSceneItem.collapseItem(); // This triggers onCollapse which unloads the scene
                }
            }

            // Lazy loading: if the new scene item is not loaded, expand it now
            if (currentSceneItem != undefined && currentSceneItem[$ "needsLoading"] == true) {
                currentSceneItem.expandItem();
            }
        } else if (asset != undefined) {
            // If the selected asset is NOT part of a scene (e.g., a standalone asset),
            // we should also collapse/clear the previous active scene if it exists.
            
            self.activeScene = undefined;
            self.activeSceneTreeviewItem = undefined;
            
            if (oldScene != undefined) {
                if (oldSceneItem != undefined) {
                    oldSceneItem.collapseItem();
                }
            }
        }
        // ------------------------------------

        sm.boxHelper.dispose();
        self.activeAsset = asset;
        self.selectedTreeviewItem = treeviewItem;

        // Add to objects for rendering only if the asset is changed
        if (assetChanged) {
            sm.objects.children = []; // Clear children without calling clear() to avoid parent issues
            
            // 1. Render active scene if present
            if (self.activeScene != undefined) {
                array_push(sm.objects.children, self.activeScene);
            }
            
            // 2. Render selected asset if it's not the scene itself and not inside it
            if (asset != undefined && asset != self.activeScene) {
                // Check if the asset is already a descendant of the active scene
                var isInScene = false;
                if (self.activeScene != undefined) {
                    var curr = asset;
                    while (curr != undefined) {
                        if (curr == self.activeScene) {
                            isInScene = true;
                            break;
                        }
                        curr = curr.parent;
                    }
                }
                
                if (!isInScene) {
                    array_push(sm.objects.children, asset);
                }
            }
        }
        
        // Attach transform controls if applicable
        // Use gizmoTarget if provided, otherwise use asset. Target is the original asset.
        self.gizmoTarget = newGizmoTarget;
        
        // Update the box helper based on the final gizmo target
        if (self.gizmoTarget != undefined && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "Object3D" || self.gizmoTarget.type == "Bone")) {
            // Show box helper if the target has geometry OR if it has children (to show expanded bbox)
            var hasGeometry = self.gizmoTarget[$ "geometry"] != undefined && self.gizmoTarget.geometry[$ "vb"] != undefined;
            var hasChildren = array_length(self.gizmoTarget.children) > 0;
            
            if (hasGeometry || hasChildren) {
                sm.boxHelper.object = self.gizmoTarget;
                
                // Update the whole scene if we are in one, and the target asset
                if (self.activeScene != undefined) oSceneEditor.assetManager.updateAssetMatrix(self.activeScene, true);
                if (self.gizmoTarget != undefined && self.gizmoTarget != self.activeScene) oSceneEditor.assetManager.updateAssetMatrix(self.gizmoTarget, true);
            }
        }
        
        if (oSceneEditor.sceneManager.transformControls != undefined && self.gizmoTarget != undefined) {
            if (self.activeTool != "view" && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "Object3D" || self.gizmoTarget.type == "Bone")) {
                oSceneEditor.sceneManager.transformControls.attach(self.gizmoTarget);
            } else {
                oSceneEditor.sceneManager.transformControls.detach();
            }
        }
    }

    /**
     * Clear the active asset selection
     */
    function clearActiveAsset(keepScene = false, clearTreeview = true) {
        // Deselect treeview item visually (for all asset types)
        if (clearTreeview) {
            var treeview = global.UI.Main.Assets.Treeview;
            
            // Deselect the currently selected item in the treeview
            if (treeview.selectedItem != undefined) {
                treeview.selectedItem.selected = false;
                treeview.selectedItem = undefined;
            }
        }
        
        var oldScene = self.activeScene;
        var oldSceneItem = self.activeSceneTreeviewItem;
        var sceneToKeep = keepScene ? self.activeScene : undefined;
        
        oSceneEditor.sceneManager.boxHelper.dispose();
        self.activeAsset = undefined;
        self.gizmoTarget = undefined;
        self.selectedTreeviewItem = undefined;
        self.renderClone = undefined;
        
        if (sceneToKeep == undefined) {
            self.activeScene = undefined;
            self.activeSceneTreeviewItem = undefined;
            
            // Collapse old scene if it was active to trigger unloading
            if (oldSceneItem != undefined) {
                oldSceneItem.collapseItem();
            }

            oSceneEditor.sceneManager.objects.clear(false);
            oSceneEditor.sceneManager.transformControls.detach();
            self.inspector.close();
        } else {
            // Re-set the scene as the active asset to maintain consistency
            self.setActiveAsset(oldScene, oldSceneItem);
            
            // Update inspector manually since we don't go through treeview callback
            if (self.inspector != undefined) {
                self.inspector.inspect(oldScene);
            }
        }
    }
    
    /**
     * Set the active tool
     * @param {String} tool - Tool name: "view", "move", "rotate", "scale"
     */
    function setTool(tool) {
        if (self.activeTool != tool) {
            self.activeTool = tool;
            
            // Update transform controls mode
            if (oSceneEditor.sceneManager.transformControls != undefined) {
                if (tool == "view") {
                    oSceneEditor.sceneManager.transformControls.detach();
                } else {
                    if (self.gizmoTarget != undefined && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "Object3D")) {
                        oSceneEditor.sceneManager.transformControls.attach(self.gizmoTarget);
                    }
                    
                    switch (tool) {
                        case "move":
                            oSceneEditor.sceneManager.transformControls.setMode("move");
                            break;
                        case "rotate":
                            oSceneEditor.sceneManager.transformControls.setMode("rotate");
                            break;
                        case "scale":
                            oSceneEditor.sceneManager.transformControls.setMode("scale");
                            break;
                    }
                }
            }
        }
    }

    function handleMouseWrap(winMouseX, winMouseY, winW, winH) {
        var sceneManager = oSceneEditor.sceneManager;
        if (mouse_button != mb_none && sceneManager.orbit.transforming) {
            var fixMousePos = false;

            if (winMouseX < 1) {
                winMouseX = winW - 2;
                fixMousePos = true;
            } else if (winMouseY < 1) {
                winMouseY = winH - 2;
                fixMousePos = true;
            } else if (winMouseX > winW - 2) {
                winMouseX = 2;
                fixMousePos = true;
            } else if (winMouseY > winH - 1) {
                winMouseY = 2;
                fixMousePos = true;
            }

            if (fixMousePos) {
                window_mouse_set(winMouseX, winMouseY); 
                
                sceneManager.orbit._prevMouseX = winMouseX;
                sceneManager.orbit._prevMouseY = winMouseY;
            }
        }
    }

    function clear() {
        self.clearActiveAsset();
    }
}
