function scrEditorInspectorTexture() {
  return [
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
              
              // Track the change in asset manager
              oSceneEditor.assetManager.editAsset(self.asset);
          }
      }
  ];
}