function scrEditorInspectorMesh() {
  return [
    // === PREVIEW ===
    {
        id: "preview",
        type: "meshPreview"
    },

    // === SECTION: GENERAL ===
    { 
          id: "name",
          field: "name",
          label: "Name", 
          type: "text"
    }, 
    { 
          id: "static",
          field: "__matrixAutoUpdate",
          label: "Static", 
          type: "checkbox",
          tooltip: "Mark object as static (disable automatic matrix updates)",
          valueGetter: function() {
              if (self.asset[$ "__matrixAutoUpdate"] == undefined) {
                  self.asset.__matrixAutoUpdate = self.asset[$ "matrixAutoUpdate"] ?? true;
              }
              return !self.asset.__matrixAutoUpdate;
          },
          onChange: function(value) {
              self.asset.__matrixAutoUpdate = !value;
              oSceneEditor.assetManager.editAsset(self.asset);
          }
    },
    { 
        id: "material",
        field: "material",
        label: "Material", 
        type: "dropdown",
        tooltip: "Material that controls the visual appearance of this object",
        search: "Search material..",
        itemsGetter: function(searchValue) {
            var allMaterials = oSceneEditor.assetManager.getAssetsByType("Material");
            
            var uniqueMaterials = [];
            var seen = {};
            for (var i = 0; i < array_length(allMaterials); i++) {
                var _asset = allMaterials[i];
                var _key = string(ptr(_asset));
                if (seen[$ _key] == undefined) {
                    seen[$ _key] = true;
                    array_push(uniqueMaterials, _asset);
                }
            }
            
            var items = array_filter(uniqueMaterials, method({ searchValue }, function(item) {
                if (searchValue == "") return true;
                return string_pos(string_trim(string_lower(searchValue)), string_lower(item.name)) > 0;
            }));
            
            var mapped = array_map(items, function(item) {
                return {
                    label: item.name, 
                    value: item
                };
            });
            
            array_insert(mapped, 0, { label: "Default", value: global.UE_DEFAULT_MATERIAL });
            return mapped;
        }
    },

    // === SECTION: TRANSFORM ===
    {
          id: "sectionTransform",
          label: "Transform", 
          type: "section",
          collapsed: false,
          children: [
            { 
                  id: "position",
                  field: "position",
                  label: "Position", 
                  type: "transformXYZ",
                  valueGetter: function() {
                      return self.asset.position;
                  },
                  onBlur: function(value) {
                      vec3_set(self.asset.position, value[0], value[1], value[2]);
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
                      euler_set(euler, value[0], value[1], value[2]);
                      self.asset.setRotation(value[0], value[1], value[2]);
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
                      vec3_set(self.asset.scale, value[0], value[1], value[2]);
                  }
            }
          ]
    },   

    // === SECTION: GAMEMAKER INTEGRATION ===
    {
          id: "sectionGM",
          label: "GameMaker Integration",
          type: "section",
          collapsed: false,
          children: [
            {
                id: "gmObject",
                field: "gmObject",
                label: "GM Object",
                type: "dropdown",
                tooltip: "GameMaker object to instantiate with this 3D object",
                search: "Search GM object..",
                itemsGetter: function(searchValue) {
                    var allObjects = ueYypGetObjects();
                    var items = array_filter(allObjects, method({ searchValue }, function(name) {
                        if (searchValue == "") return true;
                        return string_pos(string_lower(searchValue), string_lower(name)) > 0;
                    }));
                    
                    var mapped = array_map(items, function(name) {
                        return { label: name, value: name };
                    });
                    
                    array_insert(mapped, 0, { label: "None", value: undefined });
                    return mapped;
                },
                valueGetter: function() {
                    if (self.asset == undefined || self.asset.gmObject == undefined) return undefined;
                    return self.asset.gmObject;
                },
                onChange: function(value) {
                    if (self.asset == undefined) return;
                    self.asset.gmObject = value;
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            {
                id: "gmLayer",
                field: "gmLayer",
                label: "GM Layer",
                type: "text",
                tooltip: "Layer name where the GM object will be instantiated",
                placeholder: "Instances"
            }
          ]
    },

    // === SECTION: RENDERING ===
    {
          id: "sectionRendering",
          label: "Rendering",
          type: "section",
          collapsed: true,
          children: [
            { 
                  id: "frustumCulled",
                  field: "frustumCulled",
                  label: "Frustum Culled", 
                  type: "checkbox",
                  tooltip: "Enable frustum culling (skip rendering when outside camera view)"
            },           
            { 
                  id: "castShadow",
                  field: "castShadow",
                  label: "Cast Shadow", 
                  type: "checkbox",
                  tooltip: "Whether the mesh casts shadows"
            },
            { 
                  id: "receiveShadow",
                  field: "receiveShadow",
                  label: "Receive Shadows", 
                  type: "checkbox",
                  tooltip: "Whether the mesh receives shadows"
            },
            { 
                  id: "renderOrder",
                  field: "renderOrder",
                  label: "Render Order", 
                  type: "text",
                  format: "integer",
                  negative: true,
                  tooltip: "Control rendering order (lower values render first)"
            }
          ]
    }
  ];
}
