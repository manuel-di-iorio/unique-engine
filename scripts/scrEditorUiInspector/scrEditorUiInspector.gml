function EditorUiInspector(ui) constructor {
    self.ui = ui;
    self.assimp = new UeAssimpLoader();
    
    ui.Inspector = new UiNode({ name: "Inspector", minWidth: 300, width: "20%", marginBottom: 62 }, { border: true });
    ui.Inspector.Content = new UiNode({ marginTop: 38, name: "Inspector.Content", flex: 1, height: "90%", flexDirection: "column", padding: 10 });
    
    ui.Inspector.add(ui.Inspector.Content);
    
    ui.Inspector.onDraw = method(ui.Inspector, function() {
        draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_text(self.x1 + 20, self.y1 + 8, "Inspector");
    });
    
    ui.Inspector.Content.onDraw = method(ui.Inspector.Content, function() {
        draw_set_color(global.UI_COL_INSPECTOR_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
    });
    
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
                label: "Import",
                type: "spriteFilePicker",
                onChange: function(value) {
                    self.asset.sprite = value;
                    self.asset.update();
                }
            },
            {
                id: "flipY",
                field: "flipY",
                label: "Flip Vertically",
                type: "checkbox",
                onChange: function(value) {
                    self.asset[$ self.field] = value;
                    self.asset.update();
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
            //{ 
                //id: "shader",
                //field: "shader",
                //label: "Shader", 
                //type: "dropdown",
                //items: [
                    //{ key: "Standard", value: sh_ue_standard },
                    //{ key: "Basic (unlit)", value: sh_ue_basic },
                    //{ key: "Line", value: sh_ue_line },
                    //{ key: "Sprite", value: sh_ue_sprite },
                    //{ key: "Custom (set by code)", value: undefined }
                //]
            //},
            //{ 
                //type: "section",
                //label: "Properties"
            //},
            { 
                id: "transparent",
                field: "transparent",
                label: "Transparent", 
                type: "checkbox",
                onChange: function(value) {
                    self.transparent = value;
                    self.blending = value;
                }
            },
            { 
                id: "wireframe",
                field: "wireframe",
                label: "Wireframe", 
                type: "checkbox"
            },
            //{ 
                //id: "lights",
                //field: "lights",
                //label: "Lights",
                //type: "checkbox",
                //onChange: function(value) {
                    //self.lights = value ? 2 : 0;
                //}
            //},
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
            //{ 
                //type: "section",
                //label: "Textures"
            //},
            //{ 
                //id: "texturesMap",
                //field: "textures",
                //label: "Textures", 
                //type: "texturePicker",
                //extra: { mapType: "map" }
            //},
            //{ 
                //id: "texturesEmissiveMap",
                //field: "textures",
                //label: "Textures", 
                //type: "texturePicker",
                //extra: { mapType: "emissiveMap" }
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
                id: "geometry",
                field: "geometry",
                label: "Geometry",
                type: "dropdown",
                items: [
                    { key: "Box", value: new UeBoxGeometry() },
                    { key: "Sphere", value: new UeSphereGeometry(1) },
                    { key: "Plane", value: new UePlaneGeometry() },
                    { key: "Circle", value: new UeCircleGeometry() },
                    { key: "Cone", value: new UeConeGeometry() },
                    { key: "Cylinder", value: new UeCylinderGeometry() },
                    { key: "Arrow", value: new UeArrowGeometry() },
                    { key: "Line", value: new UeLineGeometry().setPositions([ 0,0,0, 1,0,0 ]) },
                    { key: "LineSegments", value: new UeLineSegmentsGeometry().setPositions([ 0,0,0, 1,0,0, 3,0,0, 4,0,0 ]) },
                    { key: "Custom", disabled: true },
                ],
                onChange: function(value) {
                    self.geometry.dispose();
                    self.geometry = value;
                }
           },
           { 
                id: "material",
                field: "material",
                label: "Material", 
                type: "materialPicker"
           },
           {
                id: "labelPosition",
                label: "Position", 
                type: "label"
           },
           { 
                id: "positionX",
                field: "position.x",
                label: "X", 
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.position.x = value;
                }
           },
           { 
                id: "positionY",
                field: "position.y",
                label: "Y",
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.position.y = value;
                }
           },
           { 
                id: "positionZ",
                field: "position.z",
                label: "Z", 
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.position.z = value;
                }
           },
        
           {
                id: "labelRotation",
                label: "Rotation", 
                type: "label"
           },
           { 
                id: "rotationX",
                field: "rotation.x",
                label: "X", 
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.rotation.x = value;
                }
           },
           { 
                id: "rotationY",
                field: "rotation.y",
                label: "Y",
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.rotation.y = value;
                }
           },
           { 
                id: "rotationZ",
                field: "rotation.z",
                label: "Z", 
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.rotation.z = value;
                }
           },
        
           {
                id: "labelScale",
                label: "Scale", 
                type: "label"
           },
           { 
                id: "scaleX",
                field: "scale.x",
                label: "X", 
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.scale.x = value;
                }
           },
           { 
                id: "scaleY",
                field: "scale.y",
                label: "Y",
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.scale.y = value;
                }
           },
           { 
                id: "scaleZ",
                field: "scale.z",
                label: "Z", 
                type: "float",
                width: "33%",
                onChange: function(value) {
                    self.scale.z = value;
                }
           },
        ],
        
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
        var assetFields = fields[$ asset.type];
        
        // Clear the previous content
        var Content = self.ui.Inspector.Content;
        Content.destroyChildren();
        
        for (var i = 0, l = array_length(assetFields); i < l; i++) {
            var assetField = assetFields[i];
            var input = undefined;
            var width = assetField[$ "width"] ?? "100%";
            var scope = { asset, field: assetField.field };
            var marginTop = !i ? 0 : 20;
            var onChangeFn = assetField[$ "onChange"];
            var onChange = method(scope, onChangeFn != undefined ? onChangeFn : function(value, input) {
                self.asset[$ self.field] = value;
            });
            
            switch (assetField.type) {
                case "text": 
                    // Textbox
                    input = new UiTextbox({ width, height: 32, marginTop }, {
                        label: assetField.label,
                        disabled: assetField[$ "disabled"],
                        value: asset[$ assetField.field],
                        onBlur: method(scope, function(value, input) {
                            if (value == "") {
                                input.value = self.asset[$ self.field];
                                return;
                            }
                            self.asset[$ self.field] = value;
                        })
                    });
                break;  
                
                // Import a new sprite for the texture
                case "spriteFilePicker":
                    input = new UiInspectorSpriteFilePicker({ marginTop }, {
                         valueGetter: method(scope, function() { 
                            return asset.__cachedSprite;
                        }),
                        onChange
                    });
                break;
                
                case "checkbox": 
                    input = new UiCheckbox({ marginTop }, {
                        label: assetField.label,
                        value: asset[$ assetField.field],
                        onChange
                    });
                break;
            }
            
            Content.add(input);
        }
    }
}