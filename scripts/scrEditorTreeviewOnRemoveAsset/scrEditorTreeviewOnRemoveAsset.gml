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
        // Rimuovi ricorsivamente i figli (se presenti nel treeview)
        __editorTreeview_removeChildrenRecursive(treeviewItem);

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
        // Rimuovi ricorsivamente i figli (se presenti nel treeview)
        __editorTreeview_removeChildrenRecursive(treeviewItem);

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
        // Deseleziona anche se è un'istanza attiva
        if (editorManager.activeAsset == asset) {
            var keepScene = editorManager.activeScene != undefined;
            editorManager.clearActiveAsset(keepScene);
        }
        
        // Rimuovi ricorsivamente i figli (se presenti nel treeview)
        __editorTreeview_removeChildrenRecursive(treeviewItem);

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
        __editorTreeview_removeChildrenRecursive(treeviewItem);
        
        // Rimuovi la cartella dall'AssetManager
        assetManager.removeAsset("Folder", asset);
    }
}

// === HELPER FUNCTIONS ===

/**
 * Assicura che anche gli asset figli nel treeview vengano cancellati
 */
function __editorTreeview_removeChildrenRecursive(treeviewItem) {
    if (treeviewItem.Items != undefined && treeviewItem.Items.children != undefined) {
        var children = treeviewItem.Items.children;
        for (var i = 0; i < array_length(children); i++) {
            var childItem = children[i];
            // Ricorsione: pulisci l'asset del figlio
            editorTreeviewOnRemoveAsset(childItem, false);
        }
    }
}

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
    var editorManager = oSceneEditor.editorManager;
    var parentSceneTreeviewItem = undefined;
    
    // Rimuovi tutte le istanze (itera all'indietro per evitare problemi con l'array che cambia)
    for (var i = array_length(instances) - 1; i >= 0; i--) {
        var instance = instances[i];
        
        // Deseleziona se questa istanza o uno dei suoi figli è attualmente selezionato
        if (__editorTreeview_isInstanceOrChildSelected(instance, editorManager)) {
            var keepScene = editorManager.activeScene != undefined;
            editorManager.clearActiveAsset(keepScene);
        }
        
        // Usa la back-reference __treeviewItem se esiste
        if (instance[$ "__treeviewItem"] != undefined) {
            var tvItem = instance.__treeviewItem;
            parentSceneTreeviewItem = tvItem.parent; // Salva il parent per aggiornare freccia dopo
            
            // Rimuovi l'item dal parent nel treeview (Items container)
            if (tvItem.parent != undefined && tvItem.parent[$ "children"] != undefined) {
                for (var j = array_length(tvItem.parent.children) - 1; j >= 0; j--) {
                    if (tvItem.parent.children[j] == tvItem) {
                        array_delete(tvItem.parent.children, j, 1);
                        tvItem.parent.childrenLength--;
                        break;
                    }
                }
            }
            
            // Distruggi l'elemento UI
            tvItem.destroy();
            instance.__treeviewItem = undefined;
        } else if (treeview != undefined && treeview[$ "Items"] != undefined) {
            // Fallback: cerca nel treeview se non c'è back-reference
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
    
    // Aggiorna la visibility della freccia del parent TreeviewItem (Scene o Instance)
    if (parentSceneTreeviewItem != undefined && parentSceneTreeviewItem.parent != undefined) {
        var sceneTreeviewItem = parentSceneTreeviewItem.parent;
        if (sceneTreeviewItem[$ "__updateArrowVisibility"] != undefined) {
            sceneTreeviewItem.__updateArrowVisibility();
        }
    }
}

/**
 * Controlla ricorsivamente se un'istanza o uno dei suoi figli è attualmente selezionato
 */
function __editorTreeview_isInstanceOrChildSelected(instance, editorManager) {
    // Controlla sia activeAsset che gizmoTarget (per le istanze dentro scene)
    if (editorManager.activeAsset == instance || editorManager.gizmoTarget == instance) {
        return true;
    }
    
    // Controlla ricorsivamente i figli
    if (instance[$ "children"] != undefined) {
        for (var i = 0; i < array_length(instance.children); i++) {
            if (__editorTreeview_isInstanceOrChildSelected(instance.children[i], editorManager)) {
                return true;
            }
        }
    }
    
    return false;
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
    var materials = oSceneEditor.assetManager.getAssetsByType("Material");
    
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
    var models = oSceneEditor.assetManager.getAssetsByType("Mesh");
    for (var i = 0; i < array_length(models); i++) {
        __editorTreeview_unsetMaterialRecursive(models[i], targetMaterial);
    }
    
    // Rimuovi dalle scene e dai loro figli
    var scenes = oSceneEditor.assetManager.getAssetsByType("Scene");
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
