function EditorUiInspector(ui) constructor {
    self.ui = ui;
    self.assimp = new UeAssimpLoader();
    

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
    ui.Inspector.Close = new UiButton(sprUiClose, { display: "none", position: "absolute", top: 5, right: 5, width: 28, height: 28 }, { outline: true });

    with (ui.Inspector.Close) {
        self.onClick(function() {
            oSceneEditor.unsetActiveAsset();
            oSceneEditor.inspector.close();
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
                items: [
                    { label: "None", value: undefined },
                    { label: "Standard", value: sh_ue_standard },
                    { label: "Basic (unlit)", value: sh_ue_basic },
                    { label: "Line", value: sh_ue_line },
                    { label: "Sprite", value: sh_ue_sprite }
                ],
                onAfterChange: function() {
                    self.asset.build();
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
                search: "Search texture..",
                subKey: "map",
                itemsGetter: function(searchValue) {
                    var textures = array_filter(oSceneEditor.projectTextures, method({ searchValue }, function(texture) {
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
                type: "checkbox"
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
                type: "checkbox"
            },
            { 
                id: "lights",
                field: "lights",
                label: "Receive Lights",
                type: "checkbox",
                onChange: function(value) {
                    self.asset.lights = value ? 2 : 0;
                    self.asset.build();
                }
            },
            { 
                id: "side",
                field: "side",
                label: "Backface Culling", 
                type: "dropdown",
                items: [
                    { label: "No culling", value: cull_noculling },
                    { label: "Counter Clockwise", value: cull_counterclockwise },
                    { label: "Clockwise", value: cull_clockwise },
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
                type: "checkbox"
            },
            { 
                id: "depthWrite",
                field: "depthWrite",
                label: "Depth Write",
                type: "checkbox"
            },
            { 
                id: "depthFunc",
                field: "depthFunc",
                label: "Depth Function", 
                type: "dropdown",
                items: [
                    { label: "Always", value: cmpfunc_always },
                    { label: "Equal", value: cmpfunc_equal },
                    { label: "Greater", value: cmpfunc_greater },
                    { label: "Greater Equal", value: cmpfunc_greaterequal },
                    { label: "Less", value: cmpfunc_less },
                    { label: "Less Equal", value: cmpfunc_lessequal },
                    { label: "Never", value: cmpfunc_never },
                    { label: "Not Equal", value: cmpfunc_notequal },
                ]
            },
            
            { 
                id: "alphaTest",
                field: "alphaTest",
                label: "Alpha Test (0-255)", 
                type: "text",
                format: "integer",
                min: 0,
                max: 255
            },
            {
                id: "forceSinglePass",
                field: "forceSinglePass",
                label: "Force Single Pass", 
                type: "checkbox"
            },
            { 
                id: "colorWrite",
                field: "colorWrite",
                label: "Color Write", 
                type: "checkbox"
            },
            { 
                id: "blending",
                field: "blending",
                label: "Blending", 
                type: "checkbox"
            },
            { 
                id: "blendEquation",
                field: "blendEquation",
                label: "Blend Equation", 
                type: "dropdown",
                items: [
                    { label: "Add", value: bm_eq_add },
                    { label: "Max", value: bm_eq_max },
                    { label: "Min", value: bm_eq_min },
                    { label: "Reverse Subtract", value: bm_eq_reverse_subtract },
                    { label: "Subtract", value: bm_eq_subtract },
                ]
            },
            { 
                id: "blendSrc",
                field: "blendSrc",
                label: "Blend Source", 
                type: "dropdown",
                items: [
                    { label: "Zero", value: bm_zero },
                    { label: "One", value: bm_one },
                    { label: "Source Color", value: bm_src_colour },
                    { label: "Inverse Source Color", value: bm_inv_src_colour },                    
                    { label: "Source Alpha", value: bm_src_alpha },
                    { label: "Inverse Source Alpha", value: bm_inv_src_alpha },
                    { label: "Destination Alpha", value: bm_dest_alpha },
                    { label: "Inverse Destination Alpha", value: bm_inv_dest_alpha },
                    { label: "Destination Color", value: bm_dest_colour },
                    { label: "Inverse Destination Color", value: bm_inv_dest_colour },
                ]
            },
            { 
                id: "blendDst",
                field: "blendDst",
                label: "Blend Destination", 
                type: "dropdown",
                items: [
                    { label: "Zero", value: bm_zero },
                    { label: "One", value: bm_one },
                    { label: "Source Color", value: bm_src_colour },
                    { label: "Inverse Source Color", value: bm_inv_src_colour },                    
                    { label: "Source Alpha", value: bm_src_alpha },
                    { label: "Inverse Source Alpha", value: bm_inv_src_alpha },
                    { label: "Destination Alpha", value: bm_dest_alpha },
                    { label: "Inverse Destination Alpha", value: bm_inv_dest_alpha },
                    { label: "Destination Color", value: bm_dest_colour },
                    { label: "Inverse Destination Color", value: bm_inv_dest_colour },
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
                onValue: function(value) {
                    return !value;
                },
                onChange: function(value) {
                    self.matrixAutoUpdate = !value;
                }
           },
           { 
                id: "frustumCulled",
                field: "frustumCulled",
                label: "Frustum Culled", 
                type: "checkbox"
           },           
           { 
                id: "material",
                field: "material",
                label: "Material", 
                type: "dropdown",
                search: "Search material..",
                itemsGetter: function(searchValue) {
                    var items = array_filter(oSceneEditor.projectMaterials, method({ searchValue }, function(item) {
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
                id: "static",
                field: "matrixAutoUpdate",
                label: "Static", 
                type: "checkbox",
                onValue: function(value) {
                    return !value;
                },
                onChange: function(value) {
                    self.matrixAutoUpdate = !value;
                }
           },
           { 
                id: "frustumCulled",
                field: "frustumCulled",
                label: "Frustum Culled", 
                type: "checkbox"
           },           
           { 
                id: "material",
                field: "material",
                label: "Material", 
                type: "dropdown",
                search: "Search material..",
                itemsGetter: function(searchValue) {
                    var items = array_filter(oSceneEditor.projectMaterials, method({ searchValue }, function(item) {
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
                
                var _onAfterChange = self.assetField[$ "onAfterChange"];
                if (_onAfterChange != undefined) {
                    method(self, _onAfterChange)();
                } 
            });
            
            var valueGetterFn = assetField[$ "valueGetter"];
            var valueGetter = valueGetterFn != undefined ? method(scope, valueGetterFn) : undefined;
            
            var onBlurFn = assetField[$ "onBlur"];
            var onBlur = onBlurFn != undefined ? method(scope, onBlurFn) : undefined;
            
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
                            self.asset[$ self.assetField.field] = value;
                        })
                    });
                break; 
                 
                case "checkbox": 
                    input = new UiCheckbox({ flex: 1, }, {
                        value: asset[$ assetField.field],
                        valueGetter,
                        onChange
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
                        onChange,
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
                _Container.add(new UiText(assetField.label, { width: _labelWidth + 15, height: 20 }, { icon: _icon }));
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
}
