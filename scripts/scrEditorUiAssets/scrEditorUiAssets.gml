function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", /*height: "30%",*/marginBottom: 62 }, { border: true });
    ui.Assets.Treeview = new UiTreeview({ marginTop: 35, flex: 1, height: "90%", flexDirection: "column" });
    
    ui.Assets.add(ui.Assets.Treeview);
        
    ui.Assets.onDraw = method(ui.Assets, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
        draw_text(self.x1 + 20, self.y1 + 8, "Assets");
    });
        
    /** Events */
    var Treeview = ui.Assets.Treeview;
    Treeview.enableScrollbar();
        
    // Create new asset
    Treeview.onNewAsset = function(treeviewItem) {
        var assetType = treeviewItem.assetType;
        var asset;
        var assetId;
        switch (assetType) {
            case "texture": 
                asset = new UeTexture();
                assetId = global.UI_ASSETS_TEXTURES_ID++;
                array_push(oSceneEditor.projectTextures, asset);
            break;
            
            case "material": 
                asset = new UeMaterial(); 
                assetId = global.UI_ASSETS_MATERIALS_ID++;
                array_push(oSceneEditor.projectMaterials, asset);
            break;
            
            case "model": 
                asset = new UeMesh(); 
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_MODELS_ID++;
                array_push(oSceneEditor.projectModels, asset);
            break;
            
            case "light":
                asset = new UeLight(); 
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_LIGHTS_ID++;
                array_push(oSceneEditor.projectLights, asset);
            break;
            
            case "camera":
                asset = new UeObject3D();
                asset.isCamera = true;
                asset.type = "camera";
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_CAMERAS_ID++;
                array_push(oSceneEditor.projectCameras, asset);
            break;
            
            case "scene":   
                asset = new UeScene();
                assetId = global.UI_ASSETS_SCENES_ID++;
                array_push(oSceneEditor.projectScenes, asset);
            break;
        }
        
        var name = string_upper(string_char_at(assetType, 1)) + string_copy(assetType, 2, string_length(assetType) - 1) + string(assetId);
        treeviewItem.asset = asset; 
        asset.name = name;
        
        // Se l'item è stato creato sotto un parent (non root entity), stabilisci la gerarchia degli asset
        if (treeviewItem.parent != undefined && treeviewItem.parent.parent != undefined && !treeviewItem.parent.parent.entity) {
            var parentTreeviewItem = treeviewItem.parent.parent;
            if (parentTreeviewItem.asset != undefined) {
                // Stabilisci la gerarchia: il nuovo asset diventa figlio del parent asset
                parentTreeviewItem.asset.add(asset);
                // Debug: ora asset.parent dovrebbe essere == parentTreeviewItem.asset
                show_debug_message("New asset '" + asset.name + "' added under parent '" + parentTreeviewItem.asset.name + "'");
            }
        } else {
            // Asset creato al livello root
            show_debug_message("New asset '" + asset.name + "' created at root level");
        }
    };
        
    Treeview.onRemoveItem = function(treeviewItem, isSelected) { 
        if (isSelected) {
            oSceneEditor.inspector.close();
        }
        
        var assetType = treeviewItem.assetType;
        var asset = treeviewItem.asset;
        var list;
         
        switch (assetType) {
            case "texture": list = oSceneEditor.projectTextures; break;
            case "material": list = oSceneEditor.projectMaterials; break;
            case "model": list = oSceneEditor.projectModels; break;
            case "light": list = oSceneEditor.projectLights; break;
            case "camera": list = oSceneEditor.projectCameras; break;
            case "scene": list = oSceneEditor.projectScenes; break;
        }
        
        var _itemIdx = array_find_index(list, method({ asset }, function(value) {
            return value == asset;
        }))
        if (_itemIdx != -1) array_delete(list, _itemIdx, 1);
    }
            
    Treeview.onItemSelected = function(treeviewItem) {
        oSceneEditor.inspector.inspect(treeviewItem.asset); 
    };
    
    // Asset drag & drop handler
    Treeview.onAssetDrop = function(draggedTreeviewItem, targetTreeviewItem) {
        var draggedItem = draggedTreeviewItem; // Il TreeviewItem che stiamo trascinando
        var targetItem = targetTreeviewItem; // Il TreeviewItem su cui stiamo droppando
        
        // Verifica se il drop è valido
        var isValidDrop = false;
        var dropAction = "";
        
        // Regole di validazione
        // 1. Texture e Material non sono draggabili
        if (draggedItem.assetType == "texture" || draggedItem.assetType == "material") {
            return false;
        }
        
        // 2. Drop su root entity item per liberare da parent
        // Controlla se l'item è sotto un parent nella UI (non solo nell'asset)
        if ((draggedItem.assetType == "model" || draggedItem.assetType == "scene") &&
         targetItem.entity && targetItem.assetType == draggedItem.assetType && draggedItem.asset != undefined) {
            isValidDrop = true;
            dropAction = "unparent";
        }
        
        // 3. Scene può essere spostata solo sotto un'altra Scene
        else if (draggedItem.assetType == "scene") {
            if (targetItem.assetType == "scene" && !targetItem.entity) {
                isValidDrop = true;
                dropAction = "reparent";
            } else {
                return false;
            }
        }
        
        // 4. Model può essere spostato sotto un altro Model (reparenting) o sotto una Scene (istanza)
        else if (draggedItem.assetType == "model") {
            if (targetItem.assetType == "model" && !targetItem.entity) {
                isValidDrop = true;
                dropAction = "reparent";
            } else if (targetItem.assetType == "scene" && !targetItem.entity) {
                isValidDrop = true;
                dropAction = "instance";
            } else {
                return false;
            }
        }
        
        // 5. Altri tipi di asset
        else {
            // Per ora, altri tipi seguono le stesse regole dei model
            if (targetItem.assetType == draggedItem.assetType && !targetItem.entity) {
                isValidDrop = true;
                dropAction = "reparent";
            } else {
                return false;
            }
        }
        
        // Verifica che non stiamo provando a spostare un item su se stesso
        if (draggedItem == targetItem) {
            return false;
        }
        
        // Verifica che non stiamo provando a reparentare un parent dentro uno dei suoi figli
        // (questo creerebbe un ciclo nella gerarchia)
        if (dropAction == "reparent" && draggedItem.asset != undefined && targetItem.asset != undefined) {
            // Controlla se il targetItem è un discendente del draggedItem
            var currentParent = targetItem.asset.parent;
            while (currentParent != undefined) {
                if (currentParent == draggedItem.asset) {
                    return false;
                }
                currentParent = currentParent.parent;
            }
            
            // Controlla anche nella gerarchia UI del treeview
            var currentTreeviewParent = targetItem.parent;
            while (currentTreeviewParent != undefined) {
                if (currentTreeviewParent == draggedItem) {
                    return false;
                }
                currentTreeviewParent = currentTreeviewParent.parent;
            }
        }
        
        // Esegui l'azione di drop
        if (isValidDrop) {
            if (dropAction == "unparent") {
                // Rimuovi dall'asset genitore corrente
                if (draggedItem.asset.parent != undefined) {
                    draggedItem.asset.parent.remove(draggedItem.asset);
                    draggedItem.asset.parent = undefined;
                }
                
                // Salva il riferimento al parent UI corrente prima di rimuovere
                var currentUIParent = draggedItem.parent;
                
                // Aggiorna la UI del treeview: sposta l'item al livello root
                // Rimuovi dall'attuale posizione nella UI
                if (draggedItem.parent != undefined) {
                    draggedItem.parent.remove(draggedItem);
                }
                
                // Aggiungi al target root entity item
                targetItem.Items.add(draggedItem);
                
                // Espandi il target item per mostrare l'item spostato
                if (targetItem.collapsed) {
                    targetItem.expandItem();
                }
                
                // Mostra la freccia se non era visibile
                if (!targetItem.Arrow.visible) {
                    targetItem.Arrow.show();
                }
                
                // Se il parent precedente non ha più figli, nascondi la freccia
                if (currentUIParent != undefined && currentUIParent.count() == 0) {
                    // Trova il TreeviewItem parent (il nonno del draggedItem)
                    var parentTreeviewItem = currentUIParent.parent;
                    if (parentTreeviewItem != undefined && parentTreeviewItem.Arrow != undefined) {
                        parentTreeviewItem.collapseItem();
                        parentTreeviewItem.Arrow.hide();
                    }
                }
            }
            else if (dropAction == "reparent") {
                // Reparenting: sposta l'asset nella gerarchia
                
                // Rimuovi dall'asset genitore precedente
                if (draggedItem.asset.parent != undefined) {
                    draggedItem.asset.parent.remove(draggedItem.asset);
                }
                
                // Aggiungi al nuovo genitore
                targetItem.asset.add(draggedItem.asset);
                
                // Aggiorna la UI del treeview
                // draggedItem.removeFromParent();
                targetItem.Items.add(draggedItem);
                
                // Espandi il target item per mostrare il nuovo figlio
                if (targetItem.collapsed) {
                    targetItem.expandItem();
                }
                
                // Mostra la freccia se non era visibile
                if (!targetItem.Arrow.visible) {
                    targetItem.Arrow.show();
                }
            }
            else if (dropAction == "instance") {
                // Istanziazione: crea una nuova istanza del modello nella scena
                
                // Clona l'asset model
                var instanceAsset = draggedItem.asset.clone();
                instanceAsset.name = draggedItem.asset.name + "_instance";
                
                // Aggiungi l'istanza alla scena
                targetItem.asset.add(instanceAsset);
                
                // Crea un nuovo TreeviewItem per l'istanza
                var instanceTreeviewItem = new UiTreeviewItem({ 
                    name: "UiTreeview.Item", 
                    marginLeft: 15, 
                    paddingVertical: 2.5 
                }, {
                    treeview: targetItem.treeview,
                    assetType: draggedItem.assetType,
                    type: draggedItem.assetType,
                    icon: draggedItem.icon
                });
                instanceTreeviewItem.asset = instanceAsset;
                
                // Aggiungi alla UI
                targetItem.Items.add(instanceTreeviewItem);
                
                // Espandi il target item per mostrare la nuova istanza
                if (targetItem.collapsed) {
                    targetItem.expandItem();
                }
                
                // Mostra la freccia se non era visibile
                if (!targetItem.Arrow.visible) {
                    targetItem.Arrow.show();
                }
                
                // Seleziona la nuova istanza
                targetItem.treeview.__onItemSelected(instanceTreeviewItem);
            }
            
            return true;
        }
        
        return false;
    };
}
