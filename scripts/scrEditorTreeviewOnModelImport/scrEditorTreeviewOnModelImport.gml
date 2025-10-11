function editorTreeviewOnModelImport(modelAsset) {
    var path = get_open_filename("Model File (*.obj,*.fbx,*.dae,*.gltf,*.3ds,*.blend,*.max)|*.obj;*.fbx;*.dae;*.gltf;*.3ds;*.blend;*.max", "");
    if (path == "") return;

    var ui = oSceneEditor.ui;
    var assimp = oSceneEditor.assimp;
    var treeview = ui.Assets.Treeview;

    // Load the model
    var modelContainer = assimp.load(path);

    // Add the related model resources to the project and treeview
    var textures = modelContainer.textures;
    var materials = modelContainer.materials;
    var model = modelContainer.model;
    
    // 1. Add textures to project and treeview
    for (var i = 0; i < array_length(textures); i++) {
        var tex = textures[i];
        
        // Add to project
        var textureId = global.UI_ASSETS_TEXTURES_ID++;
        array_push(oSceneEditor.projectTextures, tex);
        
        // Set name if not already set
        if (tex.name == undefined || tex.name == "") {
            tex.name = "Texture" + string(textureId);
        }
        
        // Add to treeview using helper function
        var textureTreeviewItem = __editorTreeview_createTreeviewItem(tex, treeview.Textures, sprUiTexture);
    }
    
    // 2. Add materials to project and treeview
    for (var i = 0; i < array_length(materials); i++) {
        var mat = materials[i];
        
        // Add to project
        var materialId = global.UI_ASSETS_MATERIALS_ID++;
        array_push(oSceneEditor.projectMaterials, mat);
        
        // Set name if not already set
        if (mat.name == undefined || mat.name == "") {
            mat.name = "Material" + string(materialId);
        }
        
        // Add to treeview using helper function
        var materialTreeviewItem = __editorTreeview_createTreeviewItem(mat, treeview.Materials, sprUiMaterial);
    }
    
    // 3. Add model to project and treeview (with hierarchy)
    var modelId = global.UI_ASSETS_MODELS_ID++;
    array_push(oSceneEditor.projectModels, model);
    
    // Set name and properties
    if (model.name == undefined || model.name == "") {
        model.name = "Model" + string(modelId);
    }

    model.traverse(function(node) {
        node.__rotationEuler = new UeEuler();
    });
    
    // Create main model treeview item using helper function
    var modelTreeviewItem = __editorTreeview_createTreeviewItem(model, treeview.Models, sprUiObject);
    log(modelTreeviewItem) // DEBUGs
    
    // 4. Add submeshes recursively with proper hierarchy
    __editorTreeview_createTreeviewItemsForChildren(model, modelTreeviewItem, sprUiObject);
    
    // 5. Select the imported model
    treeview.__onItemSelected(modelTreeviewItem);
}
