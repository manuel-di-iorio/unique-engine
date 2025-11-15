function editorTreeviewOnRemoveAsset(treeviewItem, isSelected) {
    var assetType = treeviewItem.assetType;
    var asset = treeviewItem.asset;
    var editorManager = oSceneEditor.editorManager;
    var assetManager = oSceneEditor.assetManager;
    
    // === 1. CHIUSURA INSPECTOR SE ASSET SELEZIONATO ===
    if (isSelected || (asset != undefined && editorManager.activeAsset == asset)) {
        editorManager.clearActiveAsset();
    }
    
    // === 2. GESTIONE RIMOZIONE PER TIPO ===
    
    // Texture: rimuoverla dai material che la usano
    if (assetType == "Texture" && asset != undefined) {
        __editorTreeview_removeTextureFromMaterials(asset);
        // Rimuovi dall'AssetManager
        assetManager.removeAsset("texture", asset);
    }
    
    // Material: rimuoverlo dagli object che lo hanno
    else if (assetType == "Material" && asset != undefined) {
        __editorTreeview_removeMaterialFromObjects(asset);
        // Rimuovi dall'AssetManager
        assetManager.removeAsset("material", asset);
    }
    
    // Mesh/Model: rimuovere dal parent o dalla lista globale
    else if (assetType == "Mesh" && asset != undefined) {
        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("model", asset);
        }
    }
    
    // Scene: cancella la scena (i figli verranno cancellati automaticamente)
    else if (assetType == "Scene" && asset != undefined) {
        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("scene", asset);
        }
    }
    
    // ModelInstance/Instance: rimuovere dalla scena
    else if (asset != undefined && asset[$ "isInstance"] == true) {
        // Rimuovi l'istanza dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
        }
        
        // Rimuovi dalla lista di istanze del modello originale
        if (asset[$ "object"] != undefined && asset.object[$ "instances"] != undefined) {
            asset.object.instances.remove(asset);
        }
    }
}

// === HELPER FUNCTIONS ===

/**
 * Rimuove una texture da tutti i material che la usano
 */
function __editorTreeview_removeTextureFromMaterials(targetTexture) {
    var materials = oSceneEditor.assetManager.materials;
    
    for (var i = 0; i < array_length(materials); i++) {
        var material = materials[i];
        
        // Controlla se il material ha textures
        if (material[$ "textures"] != undefined) {
            var texNames = variable_struct_get_names(material.textures);
            
            for (var t = 0; t < array_length(texNames); t++) {
                var texName = texNames[t];
                if (material.textures[$ texName] == targetTexture) {
                    material.textures[$ texName] = undefined;
                    
                    // Rebuild il material per applicare le modifiche
                    if (material[$ "build"] != undefined) {
                        material.build();
                    }
                }
            }
        }
    }
}

/**
 * Rimuove un material da tutti gli object (mesh e scene) che lo hanno
 */
function __editorTreeview_removeMaterialFromObjects(targetMaterial) {
    // Rimuovi dai modelli
    var models = oSceneEditor.assetManager.models;
    for (var i = 0; i < array_length(models); i++) {
        __editorTreeview_unsetMaterialRecursive(models[i], targetMaterial);
    }
    
    // Rimuovi dalle scene e dai loro figli
    var scenes = oSceneEditor.assetManager.scenes;
    for (var i = 0; i < array_length(scenes); i++) {
        __editorTreeview_unsetMaterialRecursive(scenes[i], targetMaterial);
    }
}

/**
 * Ricorsiva: unsetta il material da un object e dai suoi figli
 */
function __editorTreeview_unsetMaterialRecursive(obj, targetMaterial) {
    // Rimuovi il material se corrisponde
    if (obj[$ "material"] == targetMaterial) {
        obj.material = undefined;
    }
    
    // Ricorsione sui children
    if (obj[$ "children"] != undefined) {
        for (var j = 0; j < array_length(obj.children); j++) {
            __editorTreeview_unsetMaterialRecursive(obj.children[j], targetMaterial);
        }
    }
    
    // Ricorsione sulle instances
    if (obj[$ "instances"] != undefined && obj.instances.list != undefined) {
        for (var k = 0; k < array_length(obj.instances.list); k++) {
            __editorTreeview_unsetMaterialRecursive(obj.instances.list[k], targetMaterial);
        }
    }
}
