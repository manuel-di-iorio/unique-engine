function __scrEditorInspectorMaterialGetTextures(searchValue) {
    // Cache delle texture uniche
    static _cachedTextures = undefined;
    static _cacheTime = 0;
    
    // Invalida cache dopo 1 secondo o se non esiste
    var _currentTime = current_time;
    if (_cachedTextures == undefined || _currentTime - _cacheTime > 1000) {
        var allTextures = oSceneEditor.assetManager.getAssetsByType("Texture");
        
        // Deduplica usando ds_map per performance
        var seenMap = {};
        _cachedTextures = [];
        
        for (var i = 0, l = array_length(allTextures); i < l; i++) {
            var _asset = allTextures[i];
            var _key = ptr(_asset);
            var _value = seenMap[$ _key];
            if (_value == undefined) {
                seenMap[$ _key] = true;
                array_push(_cachedTextures, _asset);
            }
        }
        
        _cacheTime = _currentTime;
    }
    
    // Preprocessa searchValue una volta sola
    var _searchLower = (searchValue == "") ? "" : string_lower(string_trim(searchValue));
    var _hasSearch = (_searchLower != "");
    
    // Filter + map in un solo passaggio
    var mapped = [{ label: "<None>", value: undefined }];
    
    for (var i = 0, l = array_length(_cachedTextures); i < l; i++) {
        var texture = _cachedTextures[i];
        
        // Skip se non matcha la ricerca
        if (_hasSearch && string_pos(_searchLower, string_lower(texture.name)) == 0) {
            continue;
        }
        
        array_push(mapped, {
            label: texture.name, 
            value: texture
        });
    }

    return mapped;
}

function scrEditorInspectorMaterial() {
  return [
      // === PREVIEW ===
      {
          id: "preview",
          type: "materialPreview"
      },

      // === SECTION: GENERAL ===
      { 
          id: "name",
          field: "name",
          label: "Name", 
          type: "text"
      },

      // === SECTION: TEXTURE MAPS ===
      { 
          type: "section",
          label: "Textures",
          collapsed: false,
          children: [
              { 
                  id: "texturesMap",
                  field: "textures",
                  label: "Albedo", 
                  type: "dropdown",
                  tooltip: "Base color/albedo texture",
                  search: "Search texture..",
                  subKey: "map",
                  itemsGetter: __scrEditorInspectorMaterialGetTextures,
                  onChange: function(value, input) {
                      variable_struct_set(self.asset.textures, "map", value);
                      self.asset.build();
                      oSceneEditor.assetManager.editAsset(self.asset);
                  }
              },
              { 
                id: "texturesNormalMap",
                field: "textures",
                label: "Normal", 
                type: "dropdown",
                tooltip: "Normal map (tangent space)",
                search: "Search texture..",
                subKey: "normalMap",
                itemsGetter: __scrEditorInspectorMaterialGetTextures,
                onChange: function(value, input) {
                    variable_struct_set(self.asset.textures, "normalMap", value);
                    self.asset.build();
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            { 
                id: "texturesOrmMap",
                field: "textures",
                label: "ORM", 
                type: "dropdown",
                tooltip: "ORM map - Occlusion (Red), Roughness (Green), Metalness (Blue)",
                search: "Search texture..",
                subKey: "ormMap",
                itemsGetter: __scrEditorInspectorMaterialGetTextures,
                onChange: function(value, input) {
                    variable_struct_set(self.asset.textures, "ormMap", value);
                    self.asset.build();
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            { 
                id: "texturesEmissiveMap",
                field: "textures",
                label: "Emissive", 
                type: "dropdown",
                tooltip: "Emissive color map",
                search: "Search texture..",
                subKey: "emissiveMap",
                itemsGetter: __scrEditorInspectorMaterialGetTextures,
                onChange: function(value, input) {
                    variable_struct_set(self.asset.textures, "emissiveMap", value);
                    self.asset.build();
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            { 
                id: "texturesAlphaMap",
                field: "textures",
                label: "Alpha", 
                type: "dropdown",
                tooltip: "Alpha map for transparency",
                search: "Search texture..",
                subKey: "alphaMap",
                itemsGetter: __scrEditorInspectorMaterialGetTextures,
                onChange: function(value, input) {
                    variable_struct_set(self.asset.textures, "alphaMap", value);
                    self.asset.build();
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            },
            { 
                id: "texturesDisplacementMap",
                field: "textures",
                label: "Displacement", 
                type: "dropdown",
                tooltip: "Displacement map for height",
                search: "Search texture..",
                subKey: "displacementMap",
                itemsGetter: __scrEditorInspectorMaterialGetTextures,
                onChange: function(value, input) {
                    variable_struct_set(self.asset.textures, "displacementMap", value);
                    self.asset.build();
                    oSceneEditor.assetManager.editAsset(self.asset);
                }
            }
          ]
      },

      // === SECTION: SURFACE PROPERTIES ===
      {
          type: "section",
          label: "Surface Properties",
          collapsed: true,
          children: [
              { 
                  id: "metalness",
                  label: "Metalness (0-1)", 
                  type: "text",
                  format: "float",
                  min: 0,
                  max: 1,
                  step: 0.0001,
                  tooltip: "How much the material is like a metal",
                  valueGetter: function() { return self.asset.uniforms.ueMetalness.value; },
                  onBlur: function(value) {
                      self.asset.setUniform("ueMetalness", value);
                      oSceneEditor.assetManager.editAsset(self.asset);
                  }
              },
              { 
                  id: "roughness",
                  label: "Roughness (0-1)", 
                  type: "text",
                  format: "float",
                  min: 0,
                  max: 1,
                  step: 0.0001,
                  tooltip: "How rough the material is",
                  valueGetter: function() { return self.asset.uniforms.ueRoughness.value; },
                  onBlur: function(value) {
                      self.asset.setUniform("ueRoughness", value);
                      oSceneEditor.assetManager.editAsset(self.asset);
                  }
              },
              { 
                  id: "opacity",
                  field: "opacity",
                  label: "Opacity (0-1)", 
                  type: "text",
                  format: "float",
                  min: 0,
                  max: 1,
                  step: 0.0001,
                  tooltip: "The opacity of the material"
              },
              { 
                  id: "emissiveIntensity",
                  label: "Emissive Intensity (0-1)", 
                  type: "text",
                  format: "float",
                  min: 0,
                  max: 10,
                  step: 0.0001,
                  tooltip: "Intensity of the emissive light",
                  valueGetter: function() { return self.asset.uniforms.ueEmissiveIntensity.value; },
                  onBlur: function(value) {
                      self.asset.setUniform("ueEmissiveIntensity", value);
                      oSceneEditor.assetManager.editAsset(self.asset);
                  }
              }
          ]
      },

      // === SECTION: AMBIENT OCCLUSION ===
      {
          type: "section",
          label: "Ambient Occlusion",
          collapsed: true,
          children: [
              { 
                  id: "aoIntensity",
                  label: "AO Intensity (0-1)", 
                  type: "text",
                  format: "float",
                  min: 0,
                  max: 1,
                  step: 0.0001,
                  tooltip: "Intensity of the ambient occlusion",
                  valueGetter: function() { return self.asset.uniforms.ueAoIntensity.value; },
                  onBlur: function(value) {
                      self.asset.setUniform("ueAoIntensity", value);
                      oSceneEditor.assetManager.editAsset(self.asset);
                  }
              },
              { 
                  id: "aoMapIntensity",
                  label: "AO Map Intensity (0-1)", 
                  type: "text",
                  format: "float",
                  min: 0,
                  max: 1,
                  step: 0.0001,
                  tooltip: "Intensity of the ambient occlusion map",
                  valueGetter: function() { return self.asset.uniforms.ueAoMapIntensity.value; },
                  onBlur: function(value) {
                      self.asset.setUniform("ueAoMapIntensity", value);
                      oSceneEditor.assetManager.editAsset(self.asset);
                  }
              }
          ]
      },
  
      // === SECTION: RENDERING & TRANSPARENCY ===
      { 
          type: "section",
          label: "Rendering & Transparency",
          collapsed: true,
          children: [
              { 
                  id: "transparent",
                  field: "transparent",
                  label: "Transparent", 
                  type: "checkbox",
                  tooltip: "Enable transparency for this material"
              },
              { 
                  id: "wireframe",
                  field: "wireframe",
                  label: "Wireframe", 
                  type: "checkbox",
                  tooltip: "Render only the edges of polygons"
              },
              { 
                  id: "forceSinglePass",
                  field: "forceSinglePass",
                  label: "Force Single Pass", 
                  type: "checkbox",
                  tooltip: "Force rendering in a single pass (disable multi-pass for transparent objects)"
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
              }
          ]
      },
  
      // === SECTION: ADVANCED (DEPTH & BLENDING) ===
      { 
          type: "section",
          label: "Advanced (Depth & Blending)",
          collapsed: true,
          children: [
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
              }
          ]
      }
  ];
}
