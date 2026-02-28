function scrEditorInspectorMesh() {
  return [
    // === PREVIEW ===
    inspectorField_preview(),

    // === SECTION: GENERAL ===
    inspectorField_name(),
    inspectorField_static(),
    { 
        id: "material",
        field: "material",
        label: "Material", 
        type: "dropdown",
        tooltip: "Material that controls the visual appearance of this object",
        search: "Search material..",
        itemsGetter: function(searchValue) {
            var allMaterials = global.editor.assetManager.getAssetsByType("Material");
            
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
    inspectorSection_transform(),

    // === SECTION: GAMEMAKER INTEGRATION ===
    inspectorSection_gmIntegration(),

    // === SECTION: BOUNDING BOX ===
    inspectorSection_boundingBox(),

    // === SECTION: BOUNDING SPHERE ===
    inspectorSection_boundingSphere(),

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
