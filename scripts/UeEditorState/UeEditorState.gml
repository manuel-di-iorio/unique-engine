/// @description Editor State Manager - Centralized state management for the editor
/// This manages the global state of the editor including active assets, tools, and UI state

function UeEditorState() constructor {
    // Active state
    self.activeAsset = undefined;      // Currently selected asset in the treeview
    self.activeScene = undefined;       // Currently active scene being edited
    self.activeTool = "view";          // Current tool mode: "view", "move", "rotate", "scale"
    
    // UI References
    self.inspector = undefined;
    self.treeview = undefined;
    self.transformControls = undefined;
    self.objects = undefined;          // Scene objects for preview
    
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
        if (self.objects != undefined) {
            self.objects.children = [];
        }
        
        self.activeAsset = asset;
        self.selectedTreeviewItem = treeviewItem;
        
        // Add to objects for rendering
        if (self.objects != undefined && asset != undefined) {
            self.objects.add(asset);
        }
        
        // Attach transform controls if applicable
        if (self.transformControls != undefined && asset != undefined) {
            if (asset.type == "Mesh" || asset.type == "ModelInstance") {
                self.transformControls.attach(asset);
            } else {
                self.transformControls.detach();
            }
        }
    }
    
    /**
     * Clear the active asset selection
     */
    function clearActiveAsset() {
        if (self.objects != undefined) {
            self.objects.children = [];
        }
        
        self.activeAsset = undefined;
        self.selectedTreeviewItem = undefined;
        
        if (self.transformControls != undefined) {
            self.transformControls.detach();
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
            if (self.transformControls != undefined) {
                switch (tool) {
                    case "move":
                        self.transformControls.setMode("move");
                        break;
                    case "rotate":
                        self.transformControls.setMode("rotate");
                        break;
                    case "scale":
                        self.transformControls.setMode("scale");
                        break;
                    case "view":
                        // In view mode, transform controls should be in translate but not actively used
                        break;
                }
            }
        }
    }
}

// Global editor state instance
global.EditorState = new UeEditorState();
