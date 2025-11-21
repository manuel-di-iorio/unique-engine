function EditorUiInspector(ui) constructor {
    self.ui = ui;

    ui.Inspector = new UiNode({ name: "Inspector", minWidth: 350, width: "21%", marginBottom: 62, flexDirection: "column" }, { border: true });

    with (ui.Inspector) {
        function onDraw() {
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
            
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
            draw_text(self.x1 + 20, self.y1 + 8, "Inspector");
        }
    };

    // Inspector close button
    ui.Inspector.Close = new UiButton(sprUiClose, { display: "none", position: "absolute", top: 5, right: 5, width: 28, height: 28 }, { outline: true, tooltip: "Close inspector" });

    with (ui.Inspector.Close) {
        self.onClick(function() {
            oSceneEditor.editorManager.clearActiveAsset();
            self.hide();
        });
    }

    ui.Inspector.add(ui.Inspector.Close);
    
    // Content
    ui.Inspector.Content = new UiNode({ 
        marginTop: 38, name: "Inspector.Content", height: "90%", 
        flex: 1, flexDirection: "column"
    }, { pointerEvents: true });
    ui.Inspector.add(ui.Inspector.Content);

    with (ui.Inspector.Content) {
        self.enableScrollbar();

        self.onDraw = function() {
            draw_set_color(global.UI_COL_INSPECTOR_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        };
    }
    
    ui.Inspector.Content.Items = new UiNode({ name: "Inspector.Content.Items", padding: 10, paddingRight: 25, paddingBottom: 30 });
    ui.Inspector.Content.add(ui.Inspector.Content.Items);
    
    // Assets fields configuration
    fields = {
        "Texture": [
            { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
            },
            {
                id: "sprite",
                field: "sprite",
                type: "spriteFilePicker",
                onChange: function(value) {
                    self.asset.dispose();
                    self.asset.sprite = value;
                    self.asset.__cachedSprite = value;
                    self.asset.__cachedTexture = sprite_get_texture(value, 0);
                    
                    // Track the change in asset manager
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            }
        ],
        
        "Material": [
            { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
            },
            { 
                id: "shader",
                field: "shader",
                label: "Shader", 
                type: "dropdown",
                tooltip: "Select the shader program to use for rendering",
                items: [
                    { label: "None", value: undefined, tooltip: "No shader" },
                    { label: "Standard", value: sh_ue_standard, tooltip: "Shader with lighting support" },
                    { label: "Basic (unlit)", value: sh_ue_basic, tooltip: "Simple unlit shader" },
                    { label: "Line", value: sh_ue_line, tooltip: "Shader for rendering lines" },
                    { label: "Sprite", value: sh_ue_sprite, tooltip: "Shader for rendering sprites" }
                ],
                onAfterChange: function() {
                    self.asset.build();
                    
                    // Track the change in asset manager
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
        
            { 
                type: "section",
                label: "Textures"
            },
            { 
                id: "texturesMap",
                field: "textures",
                label: "Diffuse", 
                type: "dropdown",
                tooltip: "Base color/albedo texture",
                search: "Search texture..",
                subKey: "map",
                itemsGetter: function(searchValue) {
                    var allTextures = oSceneEditor.assetManager.getAllAssetsByType("Texture");
                    var textures = array_filter(allTextures, method({ searchValue }, function(texture) {
                        if (searchValue == "") return true;
                        return string_pos(string_trim(string_lower(searchValue)), string_lower(texture.name)) > 0;
                    }));
                    
                    var mapped = array_map(textures, function(texture) {
                        return {
                            label: texture.name, 
                            value: texture
                        };
                    });
                    
                    array_insert(mapped, 0, { label: "<None>", value: undefined });

                    return mapped;
                },
                onChange: function(value, input) {
                    self.asset.textures[$ "map"] = value;
                    self.asset.build();
                    
                    // Track the change in asset manager
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            //{ 
                //id: "texturesEmissiveMap",
                //field: "textures",
                //label: "Emissive", 
                //type: "dropdown",
                 //items: [{ label: "", value: undefined}],
                //search: true,
                //itemsGetter: function(searchValue) {
                    //return [];
                //},
                //onChange: function(value, input) {
                    // save in self.asset.textures[$ "emissiveMap"] = value;
                //}
            //},
        
            { 
                type: "section",
                label: "Basic Properties"
            },
            //{ 
                //id: "visible",
                //field: "visible",
                //label: "Visible", 
                //type: "checkbox"
            //},
            { 
                id: "transparent",
                field: "transparent",
                label: "Transparent", 
                type: "checkbox",
                tooltip: "Enable transparency for this material"
            },
            //{ 
                //id: "opacity",
                //field: "opacity",
                //label: "Opacity", 
                //type: "text",
                //format: "float",
                //min: 0,
                //max: 1
            //},
            { 
                id: "wireframe",
                field: "wireframe",
                label: "Wireframe", 
                type: "checkbox",
                tooltip: "Render only the edges of polygons"
            },
            { 
                id: "lights",
                field: "lights",
                label: "Receive Lights",
                type: "checkbox",
                tooltip: "Enable lighting calculations for this material",
                onChange: function(value) {
                    self.asset.lights = value ? 2 : 0;
                    self.asset.build();
                    
                    // Track the change in asset manager
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            { 
                id: "side",
                field: "side",
                label: "Backface Culling", 
                type: "dropdown",
                tooltip: "Control which polygon faces are rendered",
                items: [
                    { label: "No culling", value: cull_noculling, tooltip: "Render both front and back faces" },
                    { label: "Counter Clockwise", value: cull_counterclockwise, tooltip: "Cull counter-clockwise faces" },
                    { label: "Clockwise", value: cull_clockwise, tooltip: "Cull clockwise faces" },
                ]
            }, 
        
            { 
                type: "section",
                label: "Advanced Properties"
            },
            { 
                id: "depthTest",
                field: "depthTest",
                label: "Depth Test",
                type: "checkbox",
                tooltip: "Enable depth buffer testing for proper occlusion"
            },
            { 
                id: "depthWrite",
                field: "depthWrite",
                label: "Depth Write",
                type: "checkbox",
                tooltip: "Write to the depth buffer when rendering"
            },
            { 
                id: "depthFunc",
                field: "depthFunc",
                label: "Depth Function", 
                type: "dropdown",
                tooltip: "Comparison function for depth testing",
                items: [
                    { label: "Always", value: cmpfunc_always, tooltip: "Always pass depth test" },
                    { label: "Equal", value: cmpfunc_equal, tooltip: "Pass if depth equals" },
                    { label: "Greater", value: cmpfunc_greater, tooltip: "Pass if depth is greater" },
                    { label: "Greater Equal", value: cmpfunc_greaterequal, tooltip: "Pass if depth is greater or equal" },
                    { label: "Less", value: cmpfunc_less, tooltip: "Pass if depth is less (default)" },
                    { label: "Less Equal", value: cmpfunc_lessequal, tooltip: "Pass if depth is less or equal" },
                    { label: "Never", value: cmpfunc_never, tooltip: "Never pass depth test" },
                    { label: "Not Equal", value: cmpfunc_notequal, tooltip: "Pass if depth not equal" },
                ]
            },
            
            { 
                id: "alphaTest",
                field: "alphaTest",
                label: "Alpha Test (0-255)", 
                type: "text",
                format: "integer",
                min: 0,
                max: 255,
                tooltip: "Discard pixels with alpha below this threshold"
            },
            {
                id: "forceSinglePass",
                field: "forceSinglePass",
                label: "Force Single Pass", 
                type: "checkbox",
                tooltip: "Force rendering in a single pass (disable multi-pass for transparent objects)"
            },
            { 
                id: "colorWrite",
                field: "colorWrite",
                label: "Color Write", 
                type: "checkbox",
                tooltip: "Enable writing to the color buffer"
            },
            { 
                id: "blending",
                field: "blending",
                label: "Blending", 
                type: "checkbox",
                tooltip: "Enable color blending with the framebuffer"
            },
            { 
                id: "blendEquation",
                field: "blendEquation",
                label: "Blend Equation", 
                type: "dropdown",
                tooltip: "Mathematical operation for blending colors",
                items: [
                    { label: "Add", value: bm_eq_add, tooltip: "Source + Destination" },
                    { label: "Max", value: bm_eq_max, tooltip: "Maximum of Source and Destination" },
                    { label: "Min", value: bm_eq_min, tooltip: "Minimum of Source and Destination" },
                    { label: "Reverse Subtract", value: bm_eq_reverse_subtract, tooltip: "Destination - Source" },
                    { label: "Subtract", value: bm_eq_subtract, tooltip: "Source - Destination" },
                ]
            },
            { 
                id: "blendSrc",
                field: "blendSrc",
                label: "Blend Source", 
                type: "dropdown",
                tooltip: "Source blend factor",
                items: [
                    { label: "Zero", value: bm_zero, tooltip: "Multiply by 0" },
                    { label: "One", value: bm_one, tooltip: "Multiply by 1" },
                    { label: "Source Color", value: bm_src_colour, tooltip: "Multiply by source color" },
                    { label: "Inverse Source Color", value: bm_inv_src_colour, tooltip: "Multiply by (1 - source color)" },                    
                    { label: "Source Alpha", value: bm_src_alpha, tooltip: "Multiply by source alpha" },
                    { label: "Inverse Source Alpha", value: bm_inv_src_alpha, tooltip: "Multiply by (1 - source alpha)" },
                    { label: "Destination Alpha", value: bm_dest_alpha, tooltip: "Multiply by destination alpha" },
                    { label: "Inverse Destination Alpha", value: bm_inv_dest_alpha, tooltip: "Multiply by (1 - destination alpha)" },
                    { label: "Destination Color", value: bm_dest_colour, tooltip: "Multiply by destination color" },
                    { label: "Inverse Destination Color", value: bm_inv_dest_colour, tooltip: "Multiply by (1 - destination color)" },
                ]
            },
            { 
                id: "blendDst",
                field: "blendDst",
                label: "Blend Destination", 
                type: "dropdown",
                tooltip: "Destination blend factor",
                items: [
                    { label: "Zero", value: bm_zero, tooltip: "Multiply by 0" },
                    { label: "One", value: bm_one, tooltip: "Multiply by 1" },
                    { label: "Source Color", value: bm_src_colour, tooltip: "Multiply by source color" },
                    { label: "Inverse Source Color", value: bm_inv_src_colour, tooltip: "Multiply by (1 - source color)" },                    
                    { label: "Source Alpha", value: bm_src_alpha, tooltip: "Multiply by source alpha" },
                    { label: "Inverse Source Alpha", value: bm_inv_src_alpha, tooltip: "Multiply by (1 - source alpha)" },
                    { label: "Destination Alpha", value: bm_dest_alpha, tooltip: "Multiply by destination alpha" },
                    { label: "Inverse Destination Alpha", value: bm_inv_dest_alpha, tooltip: "Multiply by (1 - destination alpha)" },
                    { label: "Destination Color", value: bm_dest_colour, tooltip: "Multiply by destination color" },
                    { label: "Inverse Destination Color", value: bm_inv_dest_colour, tooltip: "Multiply by (1 - destination color)" },
                ]
            },
            //{ 
                //id: "emissive",
                //field: "emissive",
                //label: "Emissive color", 
                //type: "shaderColor"
            //},
            //{ 
                //id: "emissiveIntensity",
                //field: "emissiveIntensity",
                //label: "Emissive Intensity", 
                //type: "float"
            //},            
        ],
        
        "Mesh": [
           { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
           }, 
           { 
                id: "static",
                field: "matrixAutoUpdate",
                label: "Static", 
                type: "checkbox",
                tooltip: "Mark object as static (disable automatic matrix updates)",
                onValue: function(value) {
                    return !value;
                },
                onChange: function(value) {
                    self.matrixAutoUpdate = !value;
                    
                    // Track the change in asset manager
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
           },
           { 
                id: "frustumCulled",
                field: "frustumCulled",
                label: "Frustum Culled", 
                type: "checkbox",
                tooltip: "Enable frustum culling (skip rendering when outside camera view)"
           },           
           { 
                id: "material",
                field: "material",
                label: "Material", 
                type: "dropdown",
                tooltip: "Material that controls the visual appearance of this mesh",
                search: "Search material..",
                itemsGetter: function(searchValue) {
                    var allMaterials = oSceneEditor.assetManager.getAllAssetsByType("Material");
                    var items = array_filter(allMaterials, method({ searchValue }, function(item) {
                        if (searchValue == "") return true;
                        return string_pos(string_trim(string_lower(searchValue)), string_lower(item.name)) > 0;
                    }));
                    
                    var mapped = array_map(items, function(item) {
                        return {
                            label: item.name, 
                            value: item
                        };
                    });
                    
                    array_insert(mapped, 0, { label: "<None>", value: undefined });
                    return mapped;
                }
           },
        
           { 
                id: "renderOrder",
                field: "renderOrder",
                label: "Render Order", 
                type: "text",
                format: "integer",
                negative: true,
                tooltip: "Control rendering order (lower values render first)"
            },
        
           {
                id: "labelPosition",
                label: "Transform", 
                type: "section"
           },
           { 
                id: "position",
                field: "position",
                label: "Position", 
                type: "transformXYZ",
                valueGetter: function() {
                    return self.asset.position;
                },
                onBlur: function(value) {
                    self.asset.position.x = value[0];
                    self.asset.position.y = value[1];
                    self.asset.position.z = value[2];
                }
           },
        
           { 
                id: "rotation",
                field: "rotation",
                label: "Rotation", 
                type: "transformXYZ",
                valueGetter: function() {
                    return self.asset.__rotationEuler;
                },
                onBlur: function(value) {
                    var euler = self.asset.__rotationEuler;
                    euler.set(value[0], value[1], value[2]);
                    self.asset.rotation.setFromEuler(euler.x, euler.y, euler.z);
                }
           },
           { 
                id: "scale",
                field: "scale",
                label: "Scale", 
                type: "transformXYZ",
                valueGetter: function() {
                    return self.asset.scale;
                },
                onBlur: function(value) {
                    self.asset.scale.x = value[0];
                    self.asset.scale.y = value[1];
                    self.asset.scale.z = value[2];
                }
           },
        ],

        "ModelInstance": [
           {
                type: "label",
                field: "model",
                label: "Model",
                valueGetter: function() {
                    return self.asset.object.name;                    
                }
            },
            { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
           }, 
           {
                id: "visible",
                field: "visible",
                label: "Visible",
                type: "checkbox",
                tooltip: "Enable mesh visibility",
           },
           { 
                id: "static",
                field: "matrixAutoUpdate",
                label: "Static", 
                type: "checkbox",
                onValue: function(value) {
                    return !value;
                },
                onChange: function(value) {
                    self.matrixAutoUpdate = !value;
                    
                    // Track the change in asset manager
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
           },
           { 
                id: "frustumCulled",
                field: "frustumCulled",
                label: "Frustum Culled", 
                type: "checkbox",
                tooltip: "Enable frustum culling (skip rendering when outside camera view)"
           },           
           { 
                id: "material",
                field: "material",
                label: "Material", 
                type: "dropdown",
                tooltip: "Material that controls the visual appearance of this mesh",
                search: "Search material..",
                itemsGetter: function(searchValue) {
                    var allMaterials = oSceneEditor.assetManager.getAllAssetsByType("Material");
                    var items = array_filter(allMaterials, method({ searchValue }, function(item) {
                        if (searchValue == "") return true;
                        return string_pos(string_trim(string_lower(searchValue)), string_lower(item.name)) > 0;
                    }));
                    
                    var mapped = array_map(items, function(item) {                        
                        return {
                            label: item.name, 
                            value: item
                        };
                    });
                    
                    array_insert(mapped, 0, { label: "<None>", value: undefined });
                    return mapped;
                }
           },
        
           { 
                id: "renderOrder",
                field: "renderOrder",
                label: "Render Order", 
                type: "text",
                format: "integer",
                negative: true,
            },
        
           {
                id: "labelPosition",
                label: "Transform", 
                type: "section"
           },
           { 
                id: "position",
                field: "position",
                label: "Position", 
                type: "transformXYZ",
                valueGetter: function() {
                    return self.asset.position;
                },
                onBlur: function(value) {
                    self.asset.position.x = value[0];
                    self.asset.position.y = value[1];
                    self.asset.position.z = value[2];
                }
           },
        
           { 
                id: "rotation",
                field: "rotation",
                label: "Rotation", 
                type: "transformXYZ",
                valueGetter: function() {
                    return self.asset.__rotationEuler;
                },
                onBlur: function(value) {
                    var euler = self.asset.__rotationEuler;
                    euler.set(value[0], value[1], value[2]);
                    self.asset.rotation.setFromEuler(euler.x, euler.y, euler.z);
                }
           },
           { 
                id: "scale",
                field: "scale",
                label: "Scale", 
                type: "transformXYZ",
                valueGetter: function() {
                    return self.asset.scale;
                },
                onBlur: function(value) {
                    self.asset.scale.x = value[0];
                    self.asset.scale.y = value[1];
                    self.asset.scale.z = value[2];
                }
           },
        ],
        
        // "ModelInstance": [
        //    {
        //         type: "label",
        //         field: "model",
        //         label: "Model",
        //         valueGetter: function() {
        //             return self.asset.object.name;                    
        //         }
        //    },
        //    { 
        //         id: "visible",
        //         field: "visible",
        //         label: "Visible", 
        //         type: "checkbox"
        //    },
        //    {
        //         id: "labelTransform",
        //         label: "Transform", 
        //         type: "label"
        //    },
        //    { 
        //         id: "position",
        //         field: "position",
        //         label: "Position", 
        //         type: "transformXYZ",
        //         valueGetter: function() {
        //             return self.asset.position;
        //         },
        //         onBlur: function(value) {
        //             self.asset.position.x = value[0];
        //             self.asset.position.y = value[1];
        //             self.asset.position.z = value[2];
        //         }
        //    },
        //    { 
        //         id: "rotation",
        //         field: "rotation",
        //         label: "Rotation", 
        //         type: "transformXYZ",
        //         valueGetter: function() {
        //             return self.asset.__rotationEuler;
        //         },
        //         onBlur: function(value) {
        //             var euler = self.asset.__rotationEuler;
        //             euler.set(value[0], value[1], value[2]);
        //             self.asset.rotation.setFromEuler(euler.x, euler.y, euler.z);
        //         }
        //    },
        //    { 
        //         id: "scale",
        //         field: "scale",
        //         label: "Scale", 
        //         type: "transformXYZ",
        //         valueGetter: function() {
        //             return self.asset.scale;
        //         },
        //         onBlur: function(value) {
        //             self.asset.scale.x = value[0];
        //             self.asset.scale.y = value[1];
        //             self.asset.scale.z = value[2];
        //         }
        //    },
        // ],
        
        "Scene": [
           { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
           }, 
        ],
        
        "Folder": [
           { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
           }, 
        ]
    }
    
    /**
     * Dynamically create the inspector fields
     */
    function inspect(asset) {
        self.ui.Inspector.Close.show();

        var assetType = asset.type;
        var assetFields = fields[$ assetType];
        
        // Clear the previous content
        var _Items = self.ui.Inspector.Content.Items;
        self.close();
        
        // First pass: calculate the max label width among all items
        var _labelWidth = 0;
        draw_set_font(fText);
        for (var i = 0, l = array_length(assetFields); i < l; i++) {
            var _label = assetFields[i][$ "label"];
            if (_label == undefined) continue;
            _labelWidth = max(_labelWidth, string_width(_label)); 
        }
        
        // Second pass: add the labels and inputs
        for (var i = 0, l = array_length(assetFields); i < l; i++) {
            var assetField = assetFields[i];
            var input = undefined;
            var width = assetField[$ "width"] ?? "100%";
            var scope = { asset, assetField };
            var marginTop = !i ? 0 : (assetField.type == "label" ? 35 : 15);
            
            var onChangeFn = assetField[$ "onChange"];
            var onChange = method(scope, onChangeFn != undefined ? onChangeFn : function(value, input) {
                self.asset[$ self.assetField.field] = value;
                
                // Track the change in asset manager
                oSceneEditor.assetManager.editAsset(self.asset);
                
                var _onAfterChange = self.assetField[$ "onAfterChange"];
                if (_onAfterChange != undefined) {
                    method(self, _onAfterChange)();
                } 
            });
            
            var valueGetterFn = assetField[$ "valueGetter"];
            var valueGetter = valueGetterFn != undefined ? method(scope, valueGetterFn) : undefined;
            
            var onBlurFn = assetField[$ "onBlur"];
            var onBlur = onBlurFn != undefined ? method(scope, function(value, input) {
                // Call the custom onBlur
                method(self, self.assetField.onBlur)(value, input);
                
                // Track the change in asset manager
                oSceneEditor.assetManager.editAsset(self.asset);
            }) : undefined;
            
            switch (assetField.type) {
                case "label":
                    input = new UiText("", { flex: 1 }, {
                        valueGetter
                    });
                break;

                // Import a new sprite for the texture
                case "spriteFilePicker":
                    input = new UiInspectorSpriteFilePicker({ flex: 1, justifyContent: "center" }, {
                         valueGetter: method(scope, function() { 
                            return asset.__cachedSprite;
                        }),
                        onChange
                    });
                break;
                
                case "transformXYZ":
                 input = new UiInspectorTransformXYZ({ flex: 1, justifyContent: "space-between", flexDirection: "row", gap: 15 }, {
                        valueGetter,
                        onBlur
                    });
                break;
                
                case "text": 
                    input = new UiTextbox({ flex: 1, height: 25 }, {
                        format: assetField[$ "format"],
                        min: assetField[$ "min"],
                        max: assetField[$ "max"],
                        negative: assetField[$ "negative"],
                        disabled: assetField[$ "disabled"],
                        value: asset[$ assetField.field],
                        valueGetter,
                        onBlur: method(scope, function(value, input) {
                            if (value == "") {
                                input.value = self.asset[$ self.assetField.field];
                                return;
                            }
                            
                            // Special validation for name field
                            if (self.assetField.field == "name") {
                                var inspector = oSceneEditor.editorManager.inspector;
                                if (!inspector.__validateAssetName(self.asset, value, input)) {
                                    return;
                                }
                            }
                            
                            self.asset[$ self.assetField.field] = value;
                            
                            // Track the change in asset manager
                            oSceneEditor.assetManager.editAsset(self.asset);
                        })
                    });
                break; 
                 
                case "checkbox": 
                    input = new UiCheckbox({ flex: 1, }, {
                        value: asset[$ assetField.field],
                        valueGetter,
                        onChange: method(scope, function(value) {
                            self.asset[$ self.assetField.field] = value;
                            
                            // Track the change in asset manager
                            oSceneEditor.assetManager.editAsset(self.asset);
                            
                            var _onChange = self.assetField[$ "onChange"];
                            if (_onChange != undefined) {
                                method(self, _onChange)(value);
                            }
                        })
                    });
                break;
                
                case "dropdown": 
                    var dropdownValue = asset[$ assetField.field];
                    if (is_struct(dropdownValue) && assetField[$ "subKey"] != undefined) {
                        dropdownValue = dropdownValue[$ assetField[$ "subKey"]];
                    }
                    input = new UiDropdown({ flex: 1, }, {
                        items: assetField[$ "items"],
                        value: dropdownValue,
                        valueGetter,
                        onChange: method(scope, function(value, input) {
                            // If subKey is present, update the sub-property
                            if (self.assetField[$ "subKey"] != undefined) {
                                self.asset[$ self.assetField.field][$ self.assetField.subKey] = value;
                            } else {
                                self.asset[$ self.assetField.field] = value;
                            }
                            
                            // Track the change in asset manager
                            oSceneEditor.assetManager.editAsset(self.asset);
                            
                            // Call custom onChange if defined
                            var _onChange = self.assetField[$ "onChange"];
                            if (_onChange != undefined) {
                                method(self, _onChange)(value, input);
                            }
                            
                            // Call custom onAfterChange if defined
                            var _onAfterChange = self.assetField[$ "onAfterChange"];
                            if (_onAfterChange != undefined) {
                                method(self, _onAfterChange)();
                            }
                        }),
                        itemsGetter: assetField[$ "itemsGetter"],
                        search: assetField[$ "search"],
                    });
                break;
            }
            
            var _Container = new UiNode({ marginTop, width: "100%", flexDirection: "row", justifyContent: "space-between", alignItems: "center" });
    
            // Item label
            var _label = assetField[$ "label"];
            if (_label != undefined) {
                var _icon = assetField.type == "section" ? sprUiSection : undefined;
                var _tooltip = assetField[$ "tooltip"];
                _Container.add(new UiText(assetField.label, { width: _labelWidth + 15, height: 20 }, { 
                    icon: _icon,
                    tooltip: _tooltip,
                    pointerEvents: true 
                }));
            }
            
            if (input != undefined) {
                _Container.add(input);
            }
            
            _Items.add(_Container);
        } 
    } 
    
    function close() {
        self.ui.Inspector.Content.Items.destroyChildren();
    }
    
    /**
     * Validate asset name changes
     * @param {Struct} asset - The asset being renamed
     * @param {String} newName - The new name to validate
     * @param {Struct} input - The textbox input for error recovery
     * @return {Bool} True if valid, false otherwise
     */
    function __validateAssetName(asset, newName, input) {
        // Check for invalid character /
        if (string_pos("/", newName) > 0) {
            show_message("Invalid character '/'. Please use a different name.");
            input.value = asset.name;
            return false;
        }
        
        // Check for duplicate names at the same level (siblings only)
        var assetManager = oSceneEditor.assetManager;
        var isDuplicate = false;
        var siblings = [];
        
        if (asset[$ "type"] == "Folder") {
            // For folders, get siblings
            if (asset[$ "parent"] != undefined) {
                // Has parent: check parent's children
                siblings = asset.parent.children;
            } else {
                // Root level: check root folders
                siblings = assetManager.folders;
            }
        } else {
            // For other assets, check siblings at same level
            if (asset[$ "parent"] != undefined) {
                // Has parent: check parent's children
                siblings = asset.parent.children;
            } else {
                // Root level: check all root assets of the same type
                siblings = assetManager.getAssetsByType(asset[$ "type"]);
            }
        }
        
        // Check if any sibling has the same name
        for (var i = 0; i < array_length(siblings); i++) {
            var sibling = siblings[i];
            if (sibling != asset && sibling.name == newName) {
                isDuplicate = true;
                break;
            }
        }
        
        if (isDuplicate) {
            show_message("An asset with this name already exists at this level. Please use a different name.");
            input.value = asset.name;
            return false;
        }
        
        // Update name in lookup map
        if (assetManager.assetsByName[$ asset.name] != undefined) {
            delete assetManager.assetsByName[$ asset.name];
        }
        assetManager.assetsByName[$ newName] = asset;
        
        return true;
    }
}
