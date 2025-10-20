function EditorUiMenu(ui) constructor {
    self.ui = ui;
    
    // Recursive function to handle children during export
    function __exportLoopChildren(entity) {
        var entityData = entity.toJSON();
        entityData.uuid = entity.uuid;
        entityData.name = entity.name;
        entityData.type = entity.type;
        
        if (entity[$ "children"] != undefined) {
            entityData.children = [];
            for (var i = 0; i < array_length(entity.children); i++) {
                array_push(entityData.children, __exportLoopChildren(entity.children[i]));
            }
        }
        
        return entityData;
    }
    
    // Recursive function to export buffer geometry for models and their children
    function __exportModelBuffers(model, projectFiles) {
        // Export this model's geometry if it exists and it's not an instance
        if (model[$ "geometry"] != undefined && !model[$ "isInstance"]) {
            var geometry = model.geometry;
            if (geometry[$ "export"] != undefined) {
                var bufferFileName = projectFiles + "\\" + model.name + ".buf";
                geometry.export(bufferFileName);
            }
        }
        
        // Recursively export children (which are also meshes)
        if (model[$ "children"] != undefined) {
            for (var i = 0; i < array_length(model.children); i++) {
                __exportModelBuffers(model.children[i], projectFiles);
            }
        }
    }
    
    // Create GameMaker sprite structure for a texture
    function __createGameMakerSprite(texture, projectLocation) {
        if (!texture[$ "sprite"] || !sprite_exists(texture.sprite)) return undefined;
        
        // Generate UUIDs for the sprite structure
        var spriteUuid = ueUuid();
        var frameUuid = ueUuid();
        var layerUuid = ueUuid();
        
        // Get sprite dimensions
        var spriteWidth = sprite_get_width(texture.sprite);
        var spriteHeight = sprite_get_height(texture.sprite);
        
        // Create sprite folder structure
        var spriteFolderPath = projectLocation + "sprites\\" + texture.name;
        var layerFolderPath = spriteFolderPath + "\\layers\\" + frameUuid;
        
        // Create directories
        directory_create(spriteFolderPath);
        directory_create(layerFolderPath);
        
        // Save main sprite image
        var mainImagePath = spriteFolderPath + "\\" + frameUuid + ".png";
        sprite_save(texture.sprite, 0, mainImagePath);
        
        // Save layer image (same as main image for simple sprites)
        var layerImagePath = layerFolderPath + "\\" + layerUuid + ".png";
        sprite_save(texture.sprite, 0, layerImagePath);
        
        // Create sprite .yy file content
        var spriteYYContent = {
            "$GMSprite": "",
            "%Name": texture.name,
            "bboxMode": 0,
            "bbox_bottom": spriteHeight - 1,
            "bbox_left": 0,
            "bbox_right": spriteWidth - 1,
            "bbox_top": 0,
            "collisionKind": 1,
            "collisionTolerance": 0,
            "DynamicTexturePage": false,
            "edgeFiltering": false,
            "For3D": false,
            "frames": [
                {
                    "$GMSpriteFrame": "",
                    "%Name": frameUuid,
                    "name": frameUuid,
                    "resourceType": "GMSpriteFrame",
                    "resourceVersion": "2.0"
                }
            ],
            "gridX": 0,
            "gridY": 0,
            "height": spriteHeight,
            "HTile": false,
            "layers": [
                {
                    "$GMImageLayer": "",
                    "%Name": layerUuid,
                    "blendMode": 0,
                    "displayName": "default",
                    "isLocked": false,
                    "name": layerUuid,
                    "opacity": 100.0,
                    "resourceType": "GMImageLayer",
                    "resourceVersion": "2.0",
                    "visible": true
                }
            ],
            "name": texture.name,
            "nineSlice": undefined,
            "origin": 4,
            "parent": {
                "name": "Demo",
                "path": "folders/Demo.yy"
            },
            "preMultiplyAlpha": false,
            "resourceType": "GMSprite",
            "resourceVersion": "2.0",
            "sequence": {
                "$GMSequence": "v1",
                "%Name": texture.name,
                "autoRecord": true,
                "backdropHeight": 768,
                "backdropImageOpacity": 0.5,
                "backdropImagePath": "",
                "backdropWidth": 1366,
                "backdropXOffset": 0.0,
                "backdropYOffset": 0.0,
                "events": {
                    "$KeyframeStore<MessageEventKeyframe>": "",
                    "Keyframes": [],
                    "resourceType": "KeyframeStore<MessageEventKeyframe>",
                    "resourceVersion": "2.0"
                },
                "eventStubScript": undefined,
                "eventToFunction": {},
                "length": 1.0,
                "lockOrigin": false,
                "moments": {
                    "$KeyframeStore<MomentsEventKeyframe>": "",
                    "Keyframes": [],
                    "resourceType": "KeyframeStore<MomentsEventKeyframe>",
                    "resourceVersion": "2.0"
                },
                "name": texture.name,
                "playback": 1,
                "playbackSpeed": 30.0,
                "playbackSpeedType": 0,
                "resourceType": "GMSequence",
                "resourceVersion": "2.0",
                "seqHeight": spriteHeight,
                "seqWidth": spriteWidth,
                "showBackdrop": true,
                "showBackdropImage": false,
                "timeUnits": 1,
                "tracks": [
                    {
                        "$GMSpriteFramesTrack": "",
                        "builtinName": 0,
                        "events": [],
                        "inheritsTrackColour": true,
                        "interpolation": 1,
                        "isCreationTrack": false,
                        "keyframes": {
                            "$KeyframeStore<SpriteFrameKeyframe>": "",
                            "Keyframes": [
                                {
                                    "$Keyframe<SpriteFrameKeyframe>": "",
                                    "Channels": {
                                        "0": {
                                            "$SpriteFrameKeyframe": "",
                                            "Id": {
                                                "name": frameUuid,
                                                "path": "sprites/" + texture.name + "/" + texture.name + ".yy"
                                            },
                                            "resourceType": "SpriteFrameKeyframe",
                                            "resourceVersion": "2.0"
                                        }
                                    },
                                    "Disabled": false,
                                    "id": ueUuid(),
                                    "IsCreationKey": false,
                                    "Key": 0.0,
                                    "Length": 1.0,
                                    "resourceType": "Keyframe<SpriteFrameKeyframe>",
                                    "resourceVersion": "2.0",
                                    "Stretch": false
                                }
                            ],
                            "resourceType": "KeyframeStore<SpriteFrameKeyframe>",
                            "resourceVersion": "2.0"
                        },
                        "modifiers": [],
                        "name": "frames",
                        "resourceType": "GMSpriteFramesTrack", 
                        "resourceVersion": "2.0",
                        "spriteId": undefined,
                        "trackColour": 0,
                        "tracks": [],
                        "traits": 0
                    }
                ],
                "visibleRange": undefined,
                "volume": 1.0,
                "xorigin": spriteWidth / 2,
                "yorigin": spriteHeight / 2
            },
            "swatchColours": undefined,
            "swfPrecision": 0.5,
            "textureGroupId": {
                "name": "Default",
                "path": "texturegroups/Default"
            },
            "type": 0,
            "VTile": false,
            "width": spriteWidth
        };
        
        // Save sprite .yy file
        var spriteYYPath = spriteFolderPath + "\\" + texture.name + ".yy";
        var spriteYYJson = json_stringify(spriteYYContent);
        var file = file_text_open_write(spriteYYPath);
        if (file != -1) {
            file_text_write_string(file, spriteYYJson);
            file_text_close(file);
        }
        
        return {
            name: texture.name,
            path: "sprites/" + texture.name + "/" + texture.name + ".yy",
            uuid: spriteUuid
        };
    }
    
    // Update the .yyp file to include new sprites
    function __updateYYPFile(yypFilePath, newSpriteEntries) {
        // Read the existing .yyp file
        if (!file_exists(yypFilePath)) return;
        
        var file = file_text_open_read(yypFilePath);
        if (file == -1) return;
        
        var yypContent = "";
        while (!file_text_eof(file)) {
            yypContent += file_text_readln(file);
        }
        file_text_close(file);
        
        // Parse the JSON
        var yypData = json_parse(yypContent);
        
        // Add new sprite entries to the resources array
        for (var i = 0; i < array_length(newSpriteEntries); i++) {
            var spriteEntry = newSpriteEntries[i];
            var newResource = {
                "id": {
                    "name": spriteEntry.name,
                    "path": spriteEntry.path
                }
            };
            array_push(yypData.resources, newResource);
        }
        
        // Write the updated .yyp file
        var updatedYypJson = json_stringify(yypData);
        var writeFile = file_text_open_write(yypFilePath);
        if (writeFile != -1) {
            file_text_write_string(writeFile, updatedYypJson);
            file_text_close(writeFile);
        }
    }
    
    ui.Menu = new UiNode({ name: "Menu", width: "100%", height: 50, flexDirection: "row", alignItems: "center", paddingLeft: 10, paddingRight: 10, marginBottom: 10  });
    ui.Menu.NewProjectBtn = new UiButton(sprUiNew, { padding: 5, marginLeft: 80, marginRight: 15, width: 15, height: 15 });
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { padding: 5, marginRight: 15, width: 15, height: 15 });
    ui.Menu.SaveProjectBtn = new UiButton(sprUiSave, { padding: 5, marginRight: 15, width: 15, height: 15 });
    
    ui.Menu.add(ui.Menu.NewProjectBtn, ui.Menu.LoadProjectBtn, ui.Menu.SaveProjectBtn); 
    
    ui.Menu.onDraw = method(ui.Menu, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_sprite(sprDemoLogo, 0, 35, ~~mean(self.y1, self.y2));
    });
    
    // Events
    ui.Menu.NewProjectBtn.onClick(function() {
        global.UI_ASSETS_TEXTURES_ID = 0;
        global.UI_ASSETS_MATERIALS_ID = 0;
        global.UI_ASSETS_MODELS_ID = 0;
        global.UI_ASSETS_LIGHTS_ID = 0;
        global.UI_ASSETS_CAMERAS_ID = 0;
        global.UI_ASSETS_SCENES_ID = 0;
        window_set_caption("Unique Engine");
        ui.destroyChildren();
        instance_destroy(oSceneEditor);
        instance_create_layer(0, 0, "Instances", oSceneEditor);
    });
    
    ui.Menu.LoadProjectBtn.onClick(function() {
        //var selectedFile = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
        var selectedFile = "C:\\Users\\Manuel\\GameMakerProjects\\Unique Engine\\Unique Engine.yyp";
        if (selectedFile == "") return;
        
        // projectLocation deve essere la cartella, non il file .yyp
        projectLocation = filename_path(selectedFile);
        projectFiles = projectLocation + "datafiles";
        projectEdited = false;
        
        var _name = filename_name(selectedFile);
        //projectName = string_copy(_name, 1, string_length(_name)-4);
        //window_set_caption($"{projectName} - Unique Engine");
        window_set_caption("New project - Unique Engine*");


    });
    
    ui.Menu.SaveProjectBtn.onClick(function() {
        // Chiedi qual è il progetto Game Maker (come nel load)
        // var selectedFile = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
        var selectedFile = "C:\\Users\\Manuel\\GameMakerProjects\\Unique Engine\\Unique Engine.yyp";
        if (selectedFile == "") return;
        
        // Salviamo le informazioni del progetto
        projectName = string_copy(filename_name(selectedFile), 1, string_length(filename_name(selectedFile))-4);
         projectLocation = filename_path(selectedFile);
        projectFiles = projectLocation + "datafiles";
        projectEdited = false;
        
        // Creiamo il file JSON con tutte le entità del progetto
        var projectData = {
            projectName,
            textures: [],
            materials: [],
            models: [],
            lights: [],
            cameras: [],
            scenes: []
        };
        
        // Esporta textures
        var entities = [
            { key: "textures", array: oSceneEditor.projectTextures },
            { key: "materials", array: oSceneEditor.projectMaterials },
            { key: "models", array: oSceneEditor.projectModels },
            { key: "lights", array: oSceneEditor.projectLights },
            { key: "cameras", array: oSceneEditor.projectCameras },
            { key: "scenes", array: oSceneEditor.projectScenes }
        ];
        
        for (var i = 0, il = array_length(entities); i < il; i++) {
            var entityInfo = entities[i];
            var entityArray = entityInfo.array;
            var entityKey = entityInfo.key;

            for (var j = 0, jl = array_length(entityArray); j < jl; j++) {
                var entity = entityArray[j];
                var entityData = self.__exportLoopChildren(entity);
                
                array_push(projectData[$ entityKey], entityData);
            }
        }
        
        // Create GameMaker sprites for textures and collect sprite entries for .yyp
        var newSpriteEntries = [];
        var textures = oSceneEditor.projectTextures;
        for (var i = 0; i < array_length(textures); i++) {
            var texture = textures[i];
            if (texture[$ "sprite"] != undefined && sprite_exists(texture.sprite)) {
                var spriteInfo = self.__createGameMakerSprite(texture, projectLocation);
                if (spriteInfo != undefined) {
                    array_push(newSpriteEntries, spriteInfo);
                }
            }
        }
        
        // Esporta buffer geometry dei modelli e dei loro children
        var models = oSceneEditor.projectModels;
        for (var i = 0, il = array_length(models); i < il; i++) {
            var model = models[i];
            self.__exportModelBuffers(model, projectFiles);
        }
        
        // Update the .yyp file with new sprite entries
        if (array_length(newSpriteEntries) > 0) {
            var yypFilePath = projectLocation + filename_name(selectedFile);
            self.__updateYYPFile(yypFilePath, newSpriteEntries);
        }
        
        // Salva il file JSON nel datafiles del progetto
        var saveFileName = projectFiles + "\\ue.json";
        log(saveFileName);
        var jsonString = json_stringify(projectData);
        
        // Crea il file e scrivi il JSON
        var file = file_text_open_write(saveFileName);
        if (file != -1) {
            file_text_write_string(file, jsonString);
            file_text_close(file);
            
            show_message_async("Progetto salvato con successo in: " + saveFileName);
        } else {
            show_message_async("Errore nel salvare il progetto!");
        }
    });
}
