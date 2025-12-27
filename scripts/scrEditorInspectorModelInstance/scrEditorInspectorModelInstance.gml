function scrEditorInspectorModelInstance() {
  return [
    {
          type: "label",
          field: "object",
          label: "Object",
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
          tooltip: "Enable instance visibility",
    },
  //    { 
  //         id: "static",
  //         field: "matrixAutoUpdate",
  //         label: "Static", 
  //         type: "checkbox", 
  //         tooltip: "Mark object as static (disable automatic matrix updates)",
  //         onValue: function(value) {
  //             return !value;
  //         },
  //         onChange: function(value) {
  //             self.matrixAutoUpdate = !value;
              
  //             // Track the change in asset manager
  //             oSceneEditor.assetManager.editAsset(self.asset);
  //         }
  //    },
  //    { 
  //         id: "frustumCulled",
  //         field: "frustumCulled",
  //         label: "Frustum Culled", 
  //         type: "checkbox",
  //         tooltip: "Enable frustum culling (skip rendering when outside camera view)"
  //    },           
    { 
          id: "material",
          field: "material",
          label: "Material", 
          type: "dropdown",
          tooltip: "Material that controls the visual appearance of this instance",
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
    }
  ];
}
