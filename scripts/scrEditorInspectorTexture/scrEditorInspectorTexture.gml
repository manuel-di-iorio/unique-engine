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
    },
    {
        id: "filter",
        field: "filter",
        label: "Filter",
        type: "dropdown",
        items: [
                { label: "Bilinear", value: true },
                { label: "Nearest", value: false }
            ],
            tooltip: "Sets the texture filtering mode (Bilinear for smoothing, Nearest for pixel-art style)",
            onChange: function(value) {
            self.asset.filter = value;
            self.asset.update();
            oSceneEditor.assetManager.editAsset(self.asset);
        }
    }
];
}
