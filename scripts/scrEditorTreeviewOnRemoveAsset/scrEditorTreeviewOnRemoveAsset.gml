function editorTreeviewOnRemoveAsset(treeviewItem, isSelected) {
    var assetType = treeviewItem.assetType;
    var asset = treeviewItem.asset;
    var editorManager = oSceneEditor.editorManager;
    var assetManager = oSceneEditor.assetManager;
    
    // === 1. CHIUSURA INSPECTOR SE ASSET SELEZIONATO ===
    if (isSelected || (asset != undefined && editorManager.activeAsset == asset)) {
        var keepScene = editorManager.activeScene != undefined;
        
        // If we are deleting the active scene itself, don't keep it
        if (assetType == "Scene" && asset == editorManager.activeScene) {
            keepScene = false;
        }
        
        editorManager.clearActiveAsset(keepScene);
    }
    
    // === 2. GESTIONE RIMOZIONE PER TIPO ===
    
    // Texture: rimuoverla dai material che la usano
    if (assetType == "Texture" && asset != undefined) {
        __editorTreeview_removeTextureFromMaterials(asset);
        // Rimuovi dall'AssetManager
        assetManager.removeAsset("Texture", asset);
    }
    
    // Material: rimuoverlo dagli object che lo hanno
    else if (assetType == "Material" && asset != undefined) {
        __editorTreeview_removeMaterialFromObjects(asset);
        // Rimuovi dall'AssetManager
        assetManager.removeAsset("Material", asset);
    }
    
    // Mesh/Model: rimuovere dal parent o dalla lista globale
    else if (assetType == "Mesh" && asset != undefined) {
        // Prima rimuovi tutte le istanze di questa mesh dalle scene
        __editorTreeview_removeMeshInstances(asset, treeviewItem.treeview);
        
        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
            // Track the deletion
            assetManager.__trackChange("delete", asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Mesh", asset);
        }
    }
    
    // Scene: cancella la scena (i figli verranno cancellati automaticamente)
    else if (assetType == "Scene" && asset != undefined) {
        // Se ha un parent, rimuovilo dal parent
        if (asset.parent != undefined) {
            asset.parent.remove(asset);
            // Track the deletion
            assetManager.__trackChange("delete", asset);
        } else {
            // Altrimenti rimuovi dalla lista globale
            assetManager.removeAsset("Scene", asset);
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
        
        // Track the deletion
        assetManager.__trackChange("delete", asset);
    }

    // Folder: rimuovere ricorsivamente tutti i figli
    else if (assetType == "Folder") {
        // Itera sui figli del treeview item per pulire i loro asset
        if (treeviewItem.Items != undefined && treeviewItem.Items.children != undefined) {
            var children = treeviewItem.Items.children;
            for (var i = 0; i < array_length(children); i++) {
                var childItem = children[i];
                // Ricorsione: pulisci l'asset del figlio
                editorTreeviewOnRemoveAsset(childItem, false);
            }
        }
        
        // Rimuovi la cartella dall'AssetManager
        assetManager.removeAsset("Folder", asset);
    }
}

// === HELPER FUNCTIONS ===

/**
 * Rimuove tutte le istanze di una mesh dalle scene
 */
function __editorTreeview_removeMeshInstances(targetMesh, treeview) {
    // Controlla se il modello ha istanze
    if (targetMesh[$ "instances"] == undefined || targetMesh.instances[$ "list"] == undefined) {
        return;
    }
    
    var instances = targetMesh.instances.list;
    var assetManager = oSceneEditor.assetManager;
    
    // Rimuovi tutte le istanze (itera all'indietro per evitare problemi con l'array che cambia)
    for (var i = array_length(instances) - 1; i >= 0; i--) {
        var instance = instances[i];
        
        // Trova e rimuovi il treeview item associato all'istanza
        if (treeview != undefined && treeview[$ "Items"] != undefined) {
            __editorTreeview_findAndRemoveTreeviewItem(treeview.Items, instance);
        }
        
        // Rimuovi l'istanza dal suo parent (scena)
        if (instance.parent != undefined) {
            instance.parent.remove(instance);
        }
        
        // Track the deletion of this instance
        assetManager.__trackChange("delete", instance);
    }
    
    // Pulisci la lista delle istanze
    targetMesh.instances.list = [];
}

/**
 * Trova ricorsivamente un treeview item per un asset e lo rimuove
 */
function __editorTreeview_findAndRemoveTreeviewItem(container, asset) {
    if (container == undefined || container.children == undefined) return false;
    
    for (var i = array_length(container.children) - 1; i >= 0; i--) {
        var child = container.children[i];
        
        // Se questo è un TreeviewItem con l'asset corrispondente, rimuovilo
        if (child[$ "asset"] != undefined && child.asset == asset) {
            child.destroy();
            return true;
        }
        
        // Altrimenti cerca ricorsivamente nei suoi figli
        if (child[$ "Items"] != undefined) {
            if (__editorTreeview_findAndRemoveTreeviewItem(child.Items, asset)) {
                return true;
            }
        }
    }
    
    return false;
}

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
