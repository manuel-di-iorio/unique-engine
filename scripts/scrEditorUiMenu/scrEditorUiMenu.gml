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
        if (model[$ "geometry"] != undefined) {
            var geometry = model.geometry;
            if (geometry[$ "export"] != undefined) {
                var bufferFileName = projectFiles + "\\" + model.name + ".buf";
                geometry.export(bufferFileName);
            }
        }
        
        // Recursively export children (which are also meshes)
        if (model[$ "children"] != undefined) {
            for (var i = 0, il = array_length(model.children); i < il; i++) {
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
        /*var spriteYYContent = {
            "bboxMode": 0,
            "bbox_bottom": spriteHeight - 1,
            "bbox_left": 0,
            "bbox_right": spriteWidth - 1,
            "bbox_top": 0,
            "collisionKind": 1,
            "collisionTolerance": 0,
            "DynamicTexturePage": false,
            "edgeFiltering": false,
            "For3D": true,
            "frames": [
            {
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
                "name": "__UeSprites",
                "path": "folders/__UeSprites.yy",
            },
            "preMultiplyAlpha": false,
            "resourceType": "GMSprite",
            "resourceVersion": "2.0",
            "sequence": {
                    "autoRecord": true,
                    "backdropHeight": 768,
                    "backdropImageOpacity": 0.5,
                    "backdropImagePath": "",
                    "backdropWidth": 1366,
                    "backdropXOffset": 0.0,
                    "backdropYOffset": 0.0,
                    "events": {
                        "Keyframes": [],
                        "resourceType": "KeyframeStore<MessageEventKeyframe>",
                        "resourceVersion": "2.0"
                    },
                    "eventStubScript": undefined,
                    "eventToFunction": {},
                    "length": 1.0,
                    "lockOrigin": false,
                    "moments": {
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
                        "builtinName": 0,
                        "events": [],
                        "inheritsTrackColour": true,
                        "interpolation": 1,
                        "isCreationTrack": false,
                        "keyframes": {
                            "Keyframes": [
                            {
                                "Channels": {
                                "0": {
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
        };*/
        
        // Set properties with special characters using accessor syntax
        // spriteYYContent[$ "$GMSprite"] = "";
        // spriteYYContent[$ "%Name"] = texture.name;
        // spriteYYContent.frames[0][$ "$GMSpriteFrame"] = "";
        // spriteYYContent.frames[0][$ "%Name"] = frameUuid;
        // spriteYYContent.layers[0][$ "$GMImageLayer"] = "";
        // spriteYYContent.layers[0][$ "%Name"] = layerUuid;
        // spriteYYContent.sequence[$ "$GMSequence"] = "v1";
        // spriteYYContent.sequence[$ "%Name"] = texture.name;
        // spriteYYContent.sequence.events[$ "$KeyframeStore<MessageEventKeyframe>"] = "";
        // spriteYYContent.sequence.moments[$ "$KeyframeStore<MomentsEventKeyframe>"] = "";
        // spriteYYContent.sequence.tracks[0][$ "$GMSpriteFramesTrack"] = "";
        // spriteYYContent.sequence.tracks[0].keyframes[$ "$KeyframeStore<SpriteFrameKeyframe>"] = "";
        // spriteYYContent.sequence.tracks[0].keyframes.Keyframes[0][$ "$Keyframe<SpriteFrameKeyframe>"] = "";
        // spriteYYContent.sequence.tracks[0].keyframes.Keyframes[0].Channels[$ "0"][$ "$SpriteFrameKeyframe"] = "";
        
        // Save sprite .yy file
        // var spriteYYPath = spriteFolderPath + "\\" + texture.name + ".yy";
        // var spriteYYJson = json_stringify(spriteYYContent);
        // var file = file_text_open_write(spriteYYPath);
        // if (file != -1) {
        //     file_text_write_string(file, spriteYYJson);
        //     file_text_close(file);
        // }
        
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
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { padding: 5, marginLeft: 80, marginRight: 15, width: 15, height: 15 });
    
    ui.Menu.add(ui.Menu.LoadProjectBtn);

    ui.Menu.onDraw = method(ui.Menu, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_sprite(sprDemoLogo, 0, 35, (self.y1 + self.y2) / 2);
    });
    
    // Load Project Button - closes current editor and goes back to project manager
    ui.Menu.LoadProjectBtn.onClick(function() {
        // Destroy current editor and return to project manager
        global.UI.destroyChildren();
        instance_destroy(oSceneEditor);
        instance_create_layer(0, 0, "Instances", oSceneEditorProjectManager);
    });
    
}
