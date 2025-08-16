function EditorUiInspector(ui) constructor {
    self.ui = ui;
    self.assimp = new UeAssimpLoader();
    
    ui.Inspector = new UiNode({ name: "Inspector", width: "20%", marginBottom: 62 }, { border: true });
    ui.Inspector.Title = new UiText("Inspector", { margin: 5, marginLeft: 10, marginRight: 10 });
    ui.Inspector.Content = new UiNode({ name: "Inspector.Content", flex: 1, height: "100%", flexDirection: "column" });
    
    ui.Inspector.add(ui.Inspector.Title, ui.Inspector.Content);
    
    ui.Inspector.Content.draw = method(ui.Inspector.Content, function() {
        draw_set_color(global.UI_COL_INSPECTOR_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
    });
    
    // Assets fields configuration
    fields = {
        "texture": [
            { 
                id: "name",
                field: "name",
                label: "Name", 
                type: "text"
            },
            {
                id: "sprite",
                field: "sprite",
                label: "Choose a sprite",
                type: "spriteFilePicker"
            }
        ],
        
        "material": [
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
                    { key: "Standard", value: sh_ue_standard },
                    { key: "Basic (unlit)", value: sh_ue_basic },
                    { key: "Line", value: sh_ue_line },
                    { key: "Sprite", value: sh_ue_sprite },
                    { key: "Custom (set by code)", value: undefined }
                ]
            },
            //{ 
                //type: "section",
                //label: "Properties"
            //},
            { 
                id: "transparent",
                field: "transparent",
                label: "Transparent", 
                type: "boolean",
                onChange: function(value) {
                    self.transparent = value;
                    self.blending = value;
                }
            },
            //{ 
                //id: "lights",
                //field: "lights",
                //label: "Lights",
                //type: "boolean",
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
            { 
                id: "texturesMap",
                field: "textures",
                label: "Textures", 
                type: "texturePicker",
                extra: { mapType: "map" }
            },
            { 
                id: "texturesEmissiveMap",
                field: "textures",
                label: "Textures", 
                type: "texturePicker",
                extra: { mapType: "emissiveMap" }
            },
        ],
        
        "mesh": [
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
                type: "boolean",
                onValue: function(value) {
                    return !value;
                },
                onChange: function(value) {
                    self.matrixAutoUpdate = !value;
                }
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
                ]
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
        ]
    }
    
    
    function inspect(asset) {
        log(asset.type)
        var assetConfig = fields[$ asset.type];
    }
}