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
    
    /**
     * Set the currently active asset
     * @param {Struct} asset - The asset to set as active
     * @param {Struct} treeviewItem - Optional treeview item reference
     * @param {Struct} gizmoTarget - Optional target for transform controls (used for instances in scenes)
     */
    function setActiveAsset(asset, treeviewItem = undefined, gizmoTarget = undefined) {
        var assetChanged = self.activeAsset != asset;
        var gizmoTargetChanged = gizmoTarget != undefined;
        
        // Se né l'asset né il gizmo target sono cambiati, esci
        if (!assetChanged && !gizmoTargetChanged) return;
        
        // Clear previous objects solo se l'asset è cambiato
        if (assetChanged && oSceneEditor.sceneManager.objects != undefined) {
            oSceneEditor.sceneManager.objects.children = [];
        }
        
        self.activeAsset = asset;
        self.selectedTreeviewItem = treeviewItem;
        
        // Add to objects for rendering solo se l'asset è cambiato
        if (assetChanged && oSceneEditor.sceneManager.objects != undefined && asset != undefined) {
            oSceneEditor.sceneManager.objects.add(asset);
        }
        
        // Attach transform controls if applicable
        // Use gizmoTarget if provided, otherwise use asset
        var targetForGizmo = gizmoTarget != undefined ? gizmoTarget : asset;
        if (oSceneEditor.sceneManager.transformControls != undefined && targetForGizmo != undefined) {
            if (targetForGizmo.type == "Mesh" || targetForGizmo.type == "ModelInstance") {
                oSceneEditor.sceneManager.transformControls.attach(targetForGizmo);
            } else {
                oSceneEditor.sceneManager.transformControls.detach();
            }
        }
    }
    
    /**
     * Clear the active asset selection
     */
    function clearActiveAsset() {
        self.activeAsset = undefined;
        self.selectedTreeviewItem = undefined;
        oSceneEditor.sceneManager.objects.children = [];
        oSceneEditor.sceneManager.transformControls.detach();
        self.inspector.close();
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
                    case "view":
                        // In view mode, transform controls should be in translate but not actively used
                        break;
                }
            }
        }
    }

    function clear() {
        self.clearActiveAsset();
    }
}
