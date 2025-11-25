function editorTreeviewOnModelImport(modelAsset) {
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
    var model = modelContainer.model;
    
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
    var folder = {
        type: "Folder",
        name: modelName,
        uuid: ueUuid(),
        children: []
    };
    
    var folderItem = new UiTreeviewItem({ 
        name: "UiTreeview.Item", 
        paddingVertical: 2.5 
    }, {
        treeview: treeview,
        name: modelName,
        assetType: "Folder",
        type: "Folder",
        icon: sprUiFolder,
        asset: folder
    });
    treeview.Items.add(folderItem);
    
    // Add folder to AssetManager
    oSceneEditor.assetManager.addAsset("Folder", folder);
    
    // 1. Add textures to project and treeview (inside folder)
    for (var i = 0; i < array_length(textures); i++) {
        var tex = textures[i];
        
        // Add to project
        var textureId = global.UI_ASSETS_TEXTURES_ID++;
        
        // Set name if not already set
        if (tex.name == undefined || tex.name == "") {
            tex.name = "Texture" + string(textureId);
        }
        
        // Add to treeview inside folder (must be done before addAsset)
        var textureTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
            paddingVertical: 2.5
        }, {
            treeview: treeview,
            assetType: "Texture",
            type: "Texture",
            icon: sprUiTexture,
            asset: tex
        });
        folderItem.addChild(textureTreeviewItem);
        
        // Add to asset manager (will auto-detect folder from __treeviewItem)
        oSceneEditor.assetManager.addAsset("Texture", tex);
    }
    
    // 2. Add materials to project and treeview (inside folder)
    for (var i = 0; i < array_length(materials); i++) {
        var mat = materials[i];
        
        // Add to project
        var materialId = global.UI_ASSETS_MATERIALS_ID++;
        
        // Set name if not already set
        if (mat.name == undefined || mat.name == "") {
            mat.name = "Material" + string(materialId);
        }
        
        // Add to treeview inside folder (must be done before addAsset)
        var materialTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
            paddingVertical: 2.5
        }, {
            treeview: treeview,
            assetType: "Material",
            type: "Material",
            icon: sprUiMaterial,
            asset: mat
        });
        folderItem.addChild(materialTreeviewItem);
        
        // Add to asset manager (will auto-detect folder from __treeviewItem)
        oSceneEditor.assetManager.addAsset("Material", mat);
    }
    
    // 3. Add model to project and treeview (with hierarchy, inside folder)
    var modelId = global.UI_ASSETS_MODELS_ID++;
    
    // Set name and properties
    if (model.name == undefined || model.name == "") {
        model.name = modelName; // Use the folder name for consistency
    }

    model.traverse(function(node) {
        node.__rotationEuler = new UeEuler();
        node.matrixAutoUpdate = false; // Editor meshes don't auto-update for performance
        node.__matrixAutoUpdate = false; // Internal field for export (false = static mesh)

        if (node[$ "geometry"] != undefined && node.geometry[$ "vb"] != undefined) {
          node.geometry.__vbClone = node.geometry.cloneVb();
          node.geometry.freeze();
        }
    });
    
    // Create main model treeview item inside folder (must be done before addAsset)
    var modelTreeviewItem = new UiTreeviewItem({
        name: "UiTreeview.Item",
        paddingVertical: 2.5
    }, {
        treeview: treeview,
        assetType: "Mesh",
        type: "Mesh",
        icon: sprUiObject,
        asset: model
    });
    folderItem.addChild(modelTreeviewItem);
    
    // Add to asset manager (will auto-detect folder from __treeviewItem)
    oSceneEditor.assetManager.addAsset("Mesh", model);
    
    // 4. Add submeshes recursively with proper hierarchy
    __editorTreeview_addModelChildrenRecursive(model, modelTreeviewItem);
    
    // 5. Select the imported model
    treeview.__onItemSelected(modelTreeviewItem);
}

function __editorTreeview_addModelChildrenRecursive(parentAsset, parentTreeviewItem) {
    if (parentAsset.children == undefined) return;
    
    for (var i = 0; i < array_length(parentAsset.children); i++) {
        var child = parentAsset.children[i];
        
        // Add to AssetManager
        // Use child.type if available, otherwise default to "Mesh"
        var type = child[$ "type"] ?? "Mesh";
        // Create Treeview Item
        var childTreeviewItem = new UiTreeviewItem({
            name: "UiTreeview.Item",
            paddingVertical: 2.5
        }, {
            treeview: parentTreeviewItem.treeview,
            assetType: type,
            type: type,
            icon: sprUiObject,
            asset: child
        });
        parentTreeviewItem.addChild(childTreeviewItem);
        
        // Add to AssetManager (now it can detect parent from __treeviewItem)
        oSceneEditor.assetManager.addAsset(type, child);
        
        // Recurse
        __editorTreeview_addModelChildrenRecursive(child, childTreeviewItem);
    }
}
