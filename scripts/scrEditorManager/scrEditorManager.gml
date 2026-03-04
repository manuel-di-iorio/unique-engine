/// @description Editor Manager - Manages editor state including selection, tools, and UI references
/// This manages the state of the editor including active assets, tools, and UI state

function EditorManager() constructor {
    // Active state
    self.activeAsset = undefined;      // Currently selected asset in the treeview
    self.activeScene = undefined;       // Currently active scene being edited
    self.activeSceneTreeviewItem = undefined; // Reference to the treeview item of the active scene
    self.activeTool = EDITOR_TOOL.View;  // Current tool mode: EDITOR_TOOL enum
    
    // UI References
    self.inspector = undefined;
    self.treeview = undefined;
    self.resources = undefined;
    
    // Selection state
    self.selectedTreeviewItem = undefined;

    // Pick system
    self.pickLastHits = [];
    self.pickLastIndex = 0;
    self.pickLastPos = undefined;
    self.pickLastTopSelectableUuid = undefined;
    
    self.gizmoTarget = undefined; // Store the target for the gizmo (The ORIGINAL asset)
    self.renderClone = undefined; // The root clone being rendered

    /**
     * Set the currently active asset
     * @param {Struct} asset - The asset to set as active
     * @param {Struct} treeviewItem - Optional treeview item reference
     * @param {Struct} gizmoTarget - Optional target for transform controls (used for instances in scenes)
     */
    function setActiveAsset(asset, treeviewItem = undefined, gizmoTarget = undefined) {
        var sm = global.editor.sceneManager;
        
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
                // Note: itAsset.type is the engine-level string type ("Scene", "Mesh", etc.)
                // set on the 3D objects themselves. ASSET_TYPE enums are used in editor-level code.
                
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
                if (self.activeScene != undefined) global.editor.assetManager.updateAssetMatrix(self.activeScene);
                if (self.gizmoTarget != undefined && self.gizmoTarget != self.activeScene) global.editor.assetManager.updateAssetMatrix(self.gizmoTarget);
            }
        }
        
        if (global.editor.sceneManager.transformControls != undefined && self.gizmoTarget != undefined) {
            if (self.activeTool != EDITOR_TOOL.View && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "Object3D" || self.gizmoTarget.type == "Bone")) {
                global.editor.sceneManager.transformControls.attach(self.gizmoTarget);
            } else {
                global.editor.sceneManager.transformControls.detach();
            }
        }
    }

    /**
     * Clear the active asset selection
     */
    function clearActiveAsset(keepScene = false, clearTreeview = true) {
        // Clear SelectionManager state only when doing a full clear
        var selMgr = global.editor.selectionManager;
        if (selMgr != undefined && clearTreeview) {
            selMgr.clear();
        }
        
        // Deselect treeview item visually (for all asset types)
        if (clearTreeview) {
            var treeview = global.UI.Main.Assets.Treeview;
            
            // Clear all treeview highlights
            treeview.Items.traverseChildren(function(child) {
                child.selected = false;
            });
            treeview.selectedItem = undefined;
            
            // Also clear Resources treeview if it exists
            if (global.UI.Main[$ "Resources"] != undefined) {
                var resTv = global.UI.Main.Resources.Treeview;
                resTv.Items.traverseChildren(function(child) {
                    child.selected = false;
                });
                resTv.selectedItem = undefined;
            }
        }
        
        var oldScene = self.activeScene;
        var oldSceneItem = self.activeSceneTreeviewItem;
        var sceneToKeep = keepScene ? self.activeScene : undefined;
        
        global.editor.sceneManager.boxHelper.dispose();
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

            global.editor.sceneManager.objects.clear(false);
            global.editor.sceneManager.transformControls.detach();
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
     * @param {Real} tool - EDITOR_TOOL enum value
     */
    function setTool(tool) {
        if (self.activeTool != tool) {
            self.activeTool = tool;
            
            // Update transform controls mode
            if (global.editor.sceneManager.transformControls != undefined) {
                if (tool == EDITOR_TOOL.View) {
                    global.editor.sceneManager.transformControls.detach();
                } else {
                    if (self.gizmoTarget != undefined && (self.gizmoTarget.type == "Mesh" || self.gizmoTarget.type == "Object3D")) {
                        global.editor.sceneManager.transformControls.attach(self.gizmoTarget);
                    }
                    
                    switch (tool) {
                        case EDITOR_TOOL.Move:
                            global.editor.sceneManager.transformControls.setMode("move");
                            break;
                        case EDITOR_TOOL.Rotate:
                            global.editor.sceneManager.transformControls.setMode("rotate");
                            break;
                        case EDITOR_TOOL.Scale:
                            global.editor.sceneManager.transformControls.setMode("scale");
                            break;
                    }
                }
            }
        }
    }

    function handleMouseWrap(winMouseX, winMouseY, winW, winH) {
        var sceneManager = global.editor.sceneManager;
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

    /**
     * Render editor UI overlays (like flythrough speed)
     */
    function renderUI() {
        var sceneManager = global.editor.sceneManager;
        var orbit = sceneManager.orbit;
        
        if (orbit.flythroughSpeedDisplayTime > 0) {
            var alpha = min(1, orbit.flythroughSpeedDisplayTime / 30); // Fade out in last 0.5 seconds
            
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_font(fText); // Using correct editor font
            
            var centerX = (orbit._sceneBounds.x1 + orbit._sceneBounds.x2) / 2;
            var centerY = (orbit._sceneBounds.y1 + orbit._sceneBounds.y2) / 2;
            
            if (centerX <= 0) centerX = window_get_width() / 2;
            if (centerY <= 0) centerY = window_get_height() / 2;
            
            // Calculate percentage (logarithmic mapping feels more natural for speed)
            var logMin = log10(orbit.flythroughSpeedMin);
            var logMax = log10(orbit.flythroughSpeedMax);
            var logCurr = log10(orbit.flythroughSpeed);
            var pct = 1 + ((logCurr - logMin) / (logMax - logMin)) * 99;
            
            var text = "Flythrough Speed: " + string_format(pct, 0, 0) + "%";
            var tw = string_width(text) + 40;
            var th = string_height(text) + 20;
            
            // Draw background
            draw_set_alpha(alpha * 0.9);
            draw_set_color(global.UI_COL_SELECTION);
            draw_roundrect_ext(centerX - tw/2, centerY - th/2, centerX + tw/2, centerY + th/2, 10, 10, false);
            
            // Draw speed text
            draw_set_alpha(alpha);
            draw_set_color(c_white);
            draw_text(centerX, centerY, text);
            
            // Reset draw settings
            draw_set_alpha(1);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            draw_set_color(c_white);
        }
    }

    function clear() {
        self.clearActiveAsset();
    }
}
