function editorTreeviewOnModelImport(treeviewItem) {
    var path = get_open_filename("Model File (*.obj,*.fbx,*.dae,*.gltf,*.3ds,*.blend,*.max,*.glb)|*.obj;*.fbx;*.dae;*.gltf;*.3ds;*.blend;*.max;*.glb", "");
    if (path == "") return;

    var ui = oSceneEditor.ui;
    var assimp = oSceneEditor.sceneManager.assimp;
    var treeview = ui.Assets.Treeview;

    // Load the model
    var modelContainer = assimp.load(path);

    // Add the related model resources to the project and treeview
    var textures = modelContainer.textures;
    var materials = modelContainer.materials;
    var model = modelContainer.root;
    
    // Extract model name from file path or use progressive ID
    var fileName = filename_name(path);
    var modelName = filename_change_ext(fileName, "");
    if (modelName == "" || modelName == undefined) {
        var modelId = global.UI_ASSETS_MODELS_ID++;
        modelName = "Object" + string(modelId);
    } else {
        // Clean the name (remove invalid characters)
        modelName = string_replace_all(modelName, " ", "_");
    }
    
    // Create a folder for this model's assets
    var folder = new EditorFolder({
        name: modelName,
    });
    
    var folderItem = new UiTreeviewItem({ 
        name: "UiTreeview.Item", 
    }, {
        treeview: treeview,
        name: modelName,
        assetType: "Folder",
        type: "Folder",
        icon: sprUiFolder,
        asset: folder
    });
    
    // Add to parent or root
    if (treeviewItem != undefined) {
        treeviewItem.addChild(folderItem);
        treeviewItem.asset.add(folder);
    } else {
        treeview.Items.add(folderItem);
    }
    
    // Add folder to AssetManager
    oSceneEditor.assetManager.addAsset("Folder", folder);
    

    // 1. Add textures to project and treeview (inside folder)
    for (var i = 0, il = array_length(textures); i < il; i++) {
        var tex = textures[i];
        
        // Add to project
        var textureId = global.UI_ASSETS_TEXTURES_ID++;
        
        // Set name if not already set
        if (tex.name == undefined || tex.name == "") {
            tex.name = "Texture" + string(textureId);
        }
        
        // Set parent folder
        folder.add(tex);
        
        // Add to treeview inside folder (must be done before addAsset)
        var textureTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
        }, {
            treeview: treeview,
            assetType: "Texture",
            type: "Texture",
            icon: sprUiTexture,
            asset: tex
        });
        folderItem.addChild(textureTreeviewItem);
        
        // Add to asset manager
        oSceneEditor.assetManager.addAsset("Texture", tex);
    }
    
    // 2. Add materials to project and treeview (inside folder)
    var materialNames = variable_struct_get_names(materials);
    for (var i = 0, il = array_length(materialNames); i < il; i++) {
        var mat = materials[$ materialNames[i]];
        
        // Add to project
        var materialId = global.UI_ASSETS_MATERIALS_ID++;
        
        // Set name if not already set
        if (mat.name == undefined || mat.name == "") {
            mat.name = "Material" + string(materialId);
        }
        
        // Set parent folder
        folder.add(mat);
        
        // Add to treeview inside folder (must be done before addAsset)
        var materialTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
        }, {
            treeview: treeview,
            assetType: "Material",
            type: "Material",
            icon: sprUiMaterial,
            asset: mat
        });
        folderItem.addChild(materialTreeviewItem);
        
        // Add to asset manager
        oSceneEditor.assetManager.addAsset("Material", mat);
    }
    
    // 3. Add model to project and treeview (with hierarchy, inside folder)

    // Initialize all nodes
    model.traverse(function(node) {
        node.name = node.name == undefined || node.name == "" ?
         "Object" + string(global.UI_ASSETS_MODELS_ID++) : node.name;
        node.__rotationEuler = euler_create();
        node.castShadow = true;
        node.receiveShadow = true;
        node.matrixAutoUpdate = false; // Editor meshes don't auto-update for performance
        node.__matrixAutoUpdate = true; // Internal field for export (true = dynamic mesh by default)

        // Clone the geometry buffer (for export) and freeze the original one for rendering performance reasons
        if (node[$ "geometry"] != undefined && node.geometry[$ "vb"] != undefined) {
          node.geometry.__vbClone = node.geometry.cloneVb();
          node.geometry.freeze();
        }

        if (node.parent != undefined) {
            node.__parentUI = node.parent;
        }
        
        // Add to AssetManager
        oSceneEditor.assetManager.addAsset("Mesh", node);
    });
    
    // Overwrite the parent UI of the root model with the correct folder asset
    folder.add(model);
    
    // Create main model treeview item inside folder
    var modelTreeviewItem = new UiTreeviewItem({
        name: "UiTreeview.Item",
    }, {
        treeview: treeview,
        assetType: "Mesh",
        type: "Mesh",
        icon: sprUiMesh,
        asset: model
    });
    folderItem.addChild(modelTreeviewItem);
    
    // Add to asset manager
    oSceneEditor.assetManager.addAsset("Mesh", model);
    
    // 4. Add submeshes recursively with proper hierarchy
    __editorTreeview_addModelChildrenRecursive(model, modelTreeviewItem);
    
    // 5. Select the imported model
    treeview.__onItemSelected(modelTreeviewItem);
}

function __editorTreeview_addModelChildrenRecursive(parentAsset, parentTreeviewItem) {
    for (var i = 0, il = array_length(parentAsset.children); i < il; i++) {
        var child = parentAsset.children[i];
        
        // Create Treeview Item
        var childTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
        }, {
            treeview: parentTreeviewItem.treeview,
            assetType: "Mesh",
            type: "Mesh",
            icon: sprUiMesh,
            asset: child
        });
        parentTreeviewItem.addChild(childTreeviewItem);
        
        // Recurse
        __editorTreeview_addModelChildrenRecursive(child, childTreeviewItem);
    }
}
