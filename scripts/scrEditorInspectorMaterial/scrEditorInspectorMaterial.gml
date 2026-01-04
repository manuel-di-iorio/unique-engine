function scrEditorInspectorMaterial() {
  return [
      { 
          id: "name",
          field: "name",
          label: "Name", 
          type: "text"
      },
    //   { 
    //       id: "shader",
    //       field: "shader",
    //       label: "Shader", 
    //       type: "dropdown",
    //       tooltip: "Select the shader program to use for rendering",
    //       items: [
    //           { label: "None", value: undefined, tooltip: "No shader" },
    //           { label: "Standard", value: sh_ue_standard, tooltip: "Shader with lighting support" },
    //           { label: "Basic (unlit)", value: sh_ue_basic, tooltip: "Simple unlit shader" },
    //           { label: "Line", value: sh_ue_line, tooltip: "Shader for rendering lines" },
    //           { label: "Sprite", value: sh_ue_sprite, tooltip: "Shader for rendering sprites" },
    //           { label: "Normals", value: sh_ue_normals, tooltip: "Shader for showing normals" }
    //       ],
    //       onAfterChange: function() {
    //           self.asset.build();
              
    //           // Track the change in asset manager
    //           oSceneEditor.assetManager.editAsset(self.asset);
    //       }
    //   },
  
      { 
          type: "section",
          label: "Textures",
          collapsed: false,
          children: [
              { 
                  id: "texturesMap",
                  field: "textures",
                  label: "Diffuse", 
                  type: "dropdown",
                  tooltip: "Base color/albedo texture",
                  search: "Search texture..",
                  subKey: "map",
                  itemsGetter: function(searchValue) {
                      var allTextures = oSceneEditor.assetManager.getAssetsByType("Texture");
                      
                      var uniqueTextures = [];
                      var seen = {};
                      for (var i = 0; i < array_length(allTextures); i++) {
                          var _asset = allTextures[i];
                          var _key = string(ptr(_asset));
                          if (seen[$ _key] == undefined) {
                              seen[$ _key] = true;
                              array_push(uniqueTextures, _asset);
                          }
                      }
                      
                      var textures = array_filter(uniqueTextures, method({ searchValue }, function(texture) {
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
              }
          ]
      },
  
      { 
          type: "section",
          label: "Basic Properties",
          collapsed: false,
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
              }
          ]
      },
  
      { 
          type: "section",
          label: "Advanced Properties",
          collapsed: true,
          children: [
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
          ]
      },];
}
