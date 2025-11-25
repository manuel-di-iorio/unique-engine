/// @description Scene Manager - Manages 3D scene, camera, renderer, and controls

function SceneManager() constructor {
    self.renderer = new UeRenderer();
    self.camera = new UePerspectiveCamera({ x: 100, y: -300, z: 70, far: 10000, view: 1 });
    self.orbit = new UeOrbitControls(self.camera, {
        shouldHandleInput: function() {
            return global.UI.Main.Scene.hovered;
        },
        onChange: function() {
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        }
    });
    self.scene = new UeScene();
    
    // Helpers
    self.grid = new UeGridHelper(10000, 50);
    self.gridEnabled = true;
    self.showBoxColliders = true;
    self.objects = new UeObject3D();
    self.transformControls = new UeTransformControls(self.camera, {
        onDrag: function() {
            oSceneEditor.assetManager.editAsset(oSceneEditor.sceneManager.transformControls.object);
        },
        onDragEnd: function() {
            global.UI.needsRedraw = true;
        }
    });

    self.boxHelper = new UeBoxHelper(undefined, c_yellow, { matrixAutoUpdate: false });
    // with (self.boxHelper) {
    //     function onBeforeRender() {
    //         if (self.needsUpdate) self.update();
    //     }
    // }
    
    // Assimp loader
    self.assimp = new UeAssimpLoader();
    
    self.scene.add(self.transformControls.getHelper());
    self.scene.add(self.grid, self.objects, self.boxHelper);
    
    // Configure mouse
    global.UE_MOUSE.view = 1;
    
    // Test lights
    self.scene.add(new UeAmbientLight(c_dkgray));
    self.scene.add(new UeDirectionalLight(30, 60));

    // Create raycaster and set from camera
    self.raycaster = new UeRaycaster();
    self.raycaster.setFromCamera(self.camera);
    
    /**
     * Handle mesh picking with mouse raycast
     * Performs contextual selection based on currently selected asset
     * @returns {bool} True if a mesh was selected, false otherwise
     */
    function handleMeshPicking() {
        self.raycaster.setFromCamera(self.camera);
        
        var objectsToTest = [];
        var recursive = false; // Default: don't check children recursively
        
        // Check if we have a Mesh selected - if so, only raycast against that mesh and its submeshes
        var selectedItem = global.UI.Main.Assets.Treeview.selectedItem;
        if (selectedItem != undefined && selectedItem.asset != undefined && 
            (selectedItem.assetType == "Mesh")) {
            // Find the root mesh by traversing up the parent hierarchy
            var rootMesh = selectedItem.asset;
            var curr = selectedItem.asset;
            var safetyCounter = 0;
            
            // Traverse up to find the top-level mesh (the one without a Mesh parent)
            while (curr.parent != undefined && safetyCounter < 1000) {
                safetyCounter++;
                var parentType = curr.parent[$ "type"];
                
                // Stop if parent is a Folder (not a Mesh)
                if (parentType == "Folder" || parentType == undefined) {
                    break;
                }
                
                // If parent is also a Mesh, continue traversing up
                if (parentType == "Mesh") {
                    rootMesh = curr.parent;
                    curr = curr.parent;
                } else {
                    break;
                }
            }
            
            // Contextual selection: only check the root mesh and its children (submeshes)
            objectsToTest = [rootMesh];
            recursive = true; // Enable recursive checking to find submeshes
        } else {
            // Default behavior: check all objects in the scene or root
            if (oSceneEditor.editorManager.activeScene != undefined) {
                objectsToTest = oSceneEditor.editorManager.activeScene.children;
            } else {
                objectsToTest = self.objects.children;
            }
        }
        
        if (array_length(objectsToTest) > 0) {
            var hits = self.raycaster.intersectObjects(objectsToTest, recursive, true);
            if (array_length(hits) > 0) {
                var hitObject = hits[0].object;
                
                // Use the back-reference to get the treeview item directly
                if (hitObject[$ "__treeviewItem"] != undefined) {
                    var treeview = global.UI.Main.Assets.Treeview;
                    treeview.__onItemSelected(hitObject.__treeviewItem);
                    return true;
                }
            }
        }
        
        return false;
    }
    
    function clear() {
        self.objects.children = [];
        self.transformControls.detach();
        self.camera.setPosition(100, -300, 70);
        self.orbit.reset();
    }
}
