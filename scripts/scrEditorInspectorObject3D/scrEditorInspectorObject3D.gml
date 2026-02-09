function scrEditorInspectorObject3D() {
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
              if (self.asset == undefined) return undefined;
              if (self.asset[$ "__matrixAutoUpdate"] == undefined) {
                  self.asset.__matrixAutoUpdate = self.asset[$ "matrixAutoUpdate"] ?? true;
              }
              return !self.asset.__matrixAutoUpdate;
          },
          onChange: function(value) {
              if (self.asset == undefined) return;
              self.asset.__matrixAutoUpdate = !value;
              oSceneEditor.assetManager.editAsset(self.asset);
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
                      return self.asset != undefined ? self.asset.position : undefined;
                  },
                  onBlur: function(value) {
                      if (self.asset != undefined) {
                          vec3_set(self.asset.position, value[0], value[1], value[2]);
                      }
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
                      if (self.asset == undefined) return;
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
                      return self.asset != undefined ? self.asset.scale : undefined;
                  },
                  onBlur: function(value) {
                      if (self.asset != undefined) {
                          vec3_set(self.asset.scale, value[0], value[1], value[2]);
                      }
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
    }
  ];
}
