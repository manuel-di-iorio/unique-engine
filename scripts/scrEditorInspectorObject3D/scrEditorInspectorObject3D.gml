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
                      if (self.asset == undefined) return undefined;
                      if (self.asset[$ "__rotationEuler"] == undefined) {
                          self.asset.__rotationEuler = euler_create();
                          euler_set_from_quaternion(self.asset.__rotationEuler, self.asset.rotation);
                      }
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
    }
  ];
}
