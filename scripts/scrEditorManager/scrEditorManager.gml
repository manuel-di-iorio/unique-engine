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
     */
    function setActiveAsset(asset, treeviewItem = undefined) {
        if (self.activeAsset == asset) return;
        
        // Clear previous objects
        if (oSceneEditor.sceneManager.objects != undefined) {
            oSceneEditor.sceneManager.objects.children = [];
        }
        
        self.activeAsset = asset;
        self.selectedTreeviewItem = treeviewItem;
        
        // Add to objects for rendering
        if (oSceneEditor.sceneManager.objects != undefined && asset != undefined) {
            oSceneEditor.sceneManager.objects.add(asset);
        }
        
        // Attach transform controls if applicable
        if (oSceneEditor.sceneManager.transformControls != undefined && asset != undefined) {
            if (asset.type == "Mesh" || asset.type == "ModelInstance") {
                oSceneEditor.sceneManager.transformControls.attach(asset);
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
