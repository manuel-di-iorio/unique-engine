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
        
        // --- Scene Management Logic ---
        var oldScene = self.activeScene;
        var oldSceneItem = self.activeSceneTreeviewItem;
        
        var currentScene = undefined;
        var currentSceneItem = undefined;

        if (asset != undefined) {
            // 1. Determine the context scene
            if ((asset[$ "type"] ?? asset[$ "assetType"]) == "Scene") {
                currentScene = asset;
                currentSceneItem = treeviewItem;
            } else {
                // Find parent scene via asset hierarchy (reliable)
                currentScene = editorTreeviewUtil_getSceneOfAsset(asset);
                
                // If we have a treeview item, try to find a corresponding scene item in its hierarchy
                // (Though now scenes aren't usually in the Scene treeview, they might be in Resources)
                var it = treeviewItem;
                while (it != undefined) {
                    var itAsset = it[$ "asset"];
                    if (itAsset == currentScene) {
                        currentSceneItem = it;
                        break;
                    }
                    if (it[$ "parent"] != undefined && it.parent[$ "parent"] != undefined) {
                        it = it.parent.parent;
                    } else {
                        it = undefined;
                    }
                }
            }
        }
        
        var sceneChanged = self.activeScene != currentScene;

        // If neither the asset nor the gizmo target nor the scene have changed, exit
        // EXCEPT if we need to force a redraw/update
        if (!assetChanged && !gizmoTargetChanged && !sceneChanged) return;

        // UNLOAD PREVIOUS SCENE IF NECESSARY
        if (oldScene != undefined && sceneChanged) {
            global.editor.projectManager.loader.unloadScene(oldScene, oldSceneItem);
        }

        // Update active scene identity
        self.activeScene = currentScene;
        self.activeSceneTreeviewItem = currentSceneItem;

        // Notify listeners (UI, etc.) about scene/asset changes
        // This is used to keep widgets (like the Scene dropdown) in sync even when the
        // active scene changes due to loading/creation or selection outside the dropdown.
        if (global.editor[$ "events"] != undefined) {
            if (sceneChanged) {
                global.editor.events.dispatch({
                    type: "activeSceneChanged",
                    data: { scene: currentScene, sceneItem: currentSceneItem }
                });
            }
            if (assetChanged) {
                global.editor.events.dispatch({
                    type: "activeAssetChanged",
                    data: { asset: asset, treeviewItem: treeviewItem, gizmoTarget: newGizmoTarget }
                });
            }
        }

        // LOAD NEW SCENE IF NECESSARY
        if (currentScene != undefined && (sceneChanged || currentScene[$ "needsLoading"] == true)) {
            // If the scene item is the Scene Panel treeview, use it as the target
            var scenePanelTreeview = global.UI.Main.Assets.Treeview;
            var loadTarget = (currentSceneItem != undefined) ? currentSceneItem : scenePanelTreeview;
            
            global.editor.projectManager.loader.loadScene(currentScene, loadTarget);
        }

        sm.boxHelper.dispose();
        self.activeAsset = asset;
        self.selectedTreeviewItem = treeviewItem;

        // Add to objects for rendering if asset or scene changed
        if (assetChanged || sceneChanged) {
            sm.objects.clear(false); // Properly clear current rendering objects
            
            // 1. Render active scene if present
            if (self.activeScene != undefined) {
                sm.objects.add(self.activeScene);
            }
            
            // 2. Render selected asset if it's not the scene itself and not already in its hierarchy
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
                        curr = curr[$ "parent"];
                    }
                }
                
                if (!isInScene) {
                    sm.objects.add(asset);
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
            // Keep scene active but do NOT open its inspector
            self.activeAsset = oldScene;
            self.selectedTreeviewItem = oldSceneItem;
            self.gizmoTarget = oldScene;
            global.editor.sceneManager.transformControls.detach();
            self.inspector.close();
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
