/// @description Editor Manager - Manages editor state including selection, tools, and UI references
/// This manages the state of the editor including active assets, tools, and UI state

function EditorManager() constructor {
    // Active state
    self.activeAsset = undefined;      // Currently selected asset in the treeview
    self.activeScene = undefined;       // Currently active scene being edited
    self.activeTool = "view";          // Current tool mode: "view", "move", "rotate", "scale"
    
    // UI References
    self.inspector = undefined;
    self.treeview = undefined;
    
    // Selection state
    self.selectedTreeviewItem = undefined;
    
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
        sm.boxHelper.dispose();
        self.activeAsset = asset;
        self.selectedTreeviewItem = treeviewItem;

        // Update active scene based on what was selected
        if (asset != undefined) {
            if (asset.type == "Scene") {
                // Scene selected directly
                self.activeScene = asset;
            } else if (asset.type == "Mesh" || asset.type == "ModelInstance") {
                // Mesh/instance selected - find parent scene via treeview
                var foundScene = undefined;
                
                if (treeviewItem != undefined && treeviewItem.parent != undefined && treeviewItem.parent.parent != undefined) {
                    var parentTreeItem = treeviewItem.parent.parent;
                    
                    if (parentTreeItem[$ "asset"] != undefined && parentTreeItem.asset.type == "Scene") {
                        foundScene = parentTreeItem.asset;
                    }
                }
                self.activeScene = foundScene;
            } else {
                // Other asset type selected - clear active scene
                self.activeScene = undefined;
            }
        } else {
            self.activeScene = undefined;
        }

        // Add to objects for rendering only if the asset is changed
        if (assetChanged) {
            sm.objects.children = []; // Clear children without calling clear() to avoid parent issues
            
            var objectToRender = undefined;
            if (self.activeScene != undefined) {
                objectToRender = self.activeScene;
            } else if (asset != undefined) {
                objectToRender = asset;
            }
            
            if (objectToRender != undefined) {
                // Not using add() because it calls removeFromParent() which breaks the hierarchy
                // Just add to children array directly for rendering purposes
                array_push(sm.objects.children, objectToRender);
            }
        }
        
        // Attach transform controls if applicable
        // Use gizmoTarget if provided, otherwise use asset. Target is the original asset.
        self.gizmoTarget = newGizmoTarget;
        
        // Update the box helper based on the final gizmo target
        if (self.gizmoTarget != undefined && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "ModelInstance")) {
            // Show box helper if the mesh has geometry OR if it has children (to show expanded bbox)
            var hasGeometry = self.gizmoTarget[$ "geometry"] != undefined && self.gizmoTarget.geometry[$ "vb"] != undefined;
            var hasChildren = array_length(self.gizmoTarget.children) > 0;
            
            if (hasGeometry || hasChildren) {
                runLater(method({ sm, target: self.gizmoTarget }, function() { 
                    sm.boxHelper.object = target;
                    oSceneEditor.assetManager.updateAssetMatrix(target);
                }));
            }
        }
        
        if (oSceneEditor.sceneManager.transformControls != undefined && self.gizmoTarget != undefined) {
            if (self.activeTool != "view" && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "ModelInstance")) {
                oSceneEditor.sceneManager.transformControls.attach(self.gizmoTarget);
            } else {
                oSceneEditor.sceneManager.transformControls.detach();
            }
        }
    }

    /**
     * Clear the active asset selection
     */
    function clearActiveAsset(keepScene = false) {
        // Deselect treeview item visually (for all asset types)
        var treeview = global.UI.Main.Assets.Treeview;
        
        // Deselect the currently selected item in the treeview
        if (treeview.selectedItem != undefined) {
            treeview.selectedItem.selected = false;
            treeview.selectedItem = undefined;
        }
        
        var sceneToKeep = keepScene ? self.activeScene : undefined;
        
        oSceneEditor.sceneManager.boxHelper.dispose();
        self.activeAsset = undefined;
        self.gizmoTarget = undefined;
        self.selectedTreeviewItem = undefined;
        self.renderClone = undefined;
        
        if (sceneToKeep == undefined) {
            oSceneEditor.sceneManager.objects.clear(false);
            self.activeScene = undefined;
            oSceneEditor.sceneManager.transformControls.detach();
            self.inspector.close();
        } else {
            // Re-set the scene as the active asset to maintain consistency
            self.setActiveAsset(sceneToKeep);
            
            // Update inspector manually since we don't go through treeview callback
            if (self.inspector != undefined) {
                self.inspector.inspect(sceneToKeep);
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
                    if (self.gizmoTarget != undefined && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "ModelInstance")) {
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

    function clear() {
        self.clearActiveAsset();
    }
}
