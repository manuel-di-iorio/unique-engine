function UiInspectorSpriteFilePicker(style = {}, props = {}): UiNode(style, props) constructor {
    var _this = self;
    self.value = props[$ "value"];
    self.valueGetter = props[$ "valueGetter"];
    self.onChange = props[$ "onChange"];
    self.spriteW = self.value && sprite_get_width(self.value);
    self.spriteH = self.value && sprite_get_height(self.value);
    
    // Image
    self.ImageContainer = new UiNode({ height: 256, alignItems: "center" });
    
    self.Image = new UiNode({ width: 256, height: 256 });
    with (self.Image) {
        function onDraw() {
            var _elem = self.parent.parent;
            var _sprite = _elem.value;
            draw_sprite_part(sprUiEmptyTransparentBg, 0, 0, 0, 256, 256, self.x1, self.y1);
            
            if (_sprite != undefined) {
                var _maxSize = 256;
                var _scale = min(_maxSize / _elem.spriteW, _maxSize / _elem.spriteH);
                
                draw_sprite_ext(_sprite, 0, self.x1, self.y1, _scale, _scale, 0, c_white, 1);
            }
            
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.x1, self.y1, self.x1 + 255, self.y1 + 255, true);
        }
    }
    self.ImageContainer.add(self.Image);
    
    // Import button
    self.Button = new UiButton("Import image", {
        height: 30,
        marginTop: 15
    });
    
    with (self.Button) {
        self.onClick(function() {
            var path = get_open_filename("Image Files (*.png,*.jpg;*.jpeg;*.gif)|*.png;*.jpg;*.jpeg;*.gif", "");
            if (path == "") return;
            
            var _sprite = sprite_add(path, 1, false, false, 0, 0);
            if (_sprite == -1) return;
            self.parent.onChange(_sprite, self.parent);
        });
    }
    
    // Info container
    self.Info = new UiNode({ display: _this.value ? "flex" : "none", height: 40, marginTop: 15 });
    with (self.Info) {
        self.onDraw = function() {
            if (!self.parent.value) return;
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            var yy = self.y1; 
            draw_text(self.x1, yy, $"Width: {self.parent.spriteW}{chr(13) + chr(10)}Height: {self.parent.spriteH}");
        }
    }
    
    self.add(self.ImageContainer, self.Button, self.Info); 
    
    // Update value from external source
    self.onStep(function() {
        if (self.valueGetter != undefined) {
            var _currentValue = self.value;
            self.value = self.valueGetter();
            
            if (self.value != undefined && self.value != _currentValue) {
                self.spriteW = sprite_get_width(self.value);
                self.spriteH = sprite_get_height(self.value);
                self.Info.show();
            }
        }
    });
}