function UiCheckbox(style = {}, props = {}) : UiNode(style, props) constructor {
    self.flexDirection = "row";
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.row);
    self.alignItems = "center";
    
    setName(props[$ "name"] ?? "UiCheckbox");
    self.value = props[$ "value"] ?? false;
    self.label = props[$ "label"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(value, input) {};
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    self.variant = props[$ "variant"] ?? "checkbox";
    self.group = props[$ "group"];
    
    self.pointerEvents = true;
    self.handpoint = true;
    
    // Input node first (the visual box/circle)
    self.Input = new UiNode({
        name: "UiCheckbox.Input", 
        width: 20,
        height: 20,
        marginRight: 10
    }, { pointerEvents: true, handpoint: true });
    self.add(self.Input);
    
    // Label node second
    if (self.label != undefined) {
        self.Label = new UiText(self.label, {}, { color: global.UI_COL_TEXT_MAIN });
        self.add(self.Label);
    }
    
    with (self.Input) {
        self.onDraw = function() {
            var isChecked = self.parent.value;
            var isRadio = (self.parent.variant == "radio");
            var _checkedSprite = isRadio ? sprUiIconRadio : sprUiIconCheckbox;
            var _uncheckedSprite = isRadio ? sprUiIconRadioUnchecked : sprUiIconCheckboxUnchecked;
            var _sprite = isChecked ? _checkedSprite : _uncheckedSprite;
            var _col = isChecked ? global.UI_COL_PRIMARY : global.UI_COL_TEXT_DIM;
            
            if (self.parent.hovered && !isChecked) {
                draw_set_color(global.UI_COL_BTN_HOVER);
                draw_roundrect_ext(self.x1 - 1, self.y1 - 1, self.x2 + 1, self.y2 + 1, 6, 6, false);
            }
            
            if (sprite_exists(_sprite)) {
                var _sw = sprite_get_width(_sprite);
                var _sh = sprite_get_height(_sprite);
                var _scale = min((self.x2 - self.x1) / _sw, (self.y2 - self.y1) / _sh);
                var _ox = sprite_get_xoffset(_sprite);
                var _oy = sprite_get_yoffset(_sprite);
                var _mx = mean(self.x1, self.x2);
                var _my = mean(self.y1, self.y2);
                draw_sprite_ext(_sprite, 0, _mx - (_sw / 2 - _ox) * _scale, _my - (_sh / 2 - _oy) * _scale, _scale, _scale, 0, _col, 1);
            }
        };
    }
    
    self.onStep(function() {
        if (self.valueGetter != undefined) self.value = self.valueGetter();
    });
    
    self.onClick(function() {
        if (self.variant == "radio" && self.value) return true; 
        
        self.value = !self.value;
        
        // Radio group logic
        if (self.variant == "radio" && self.value && self.parent != undefined) {
            var myGroup = self.group;
            if (myGroup != undefined) {
                var siblings = self.parent.children;
                for (var i = 0; i < array_length(siblings); i++) {
                    var s = siblings[i];
                    if (s != self && s[$ "variant"] == "radio" && s[$ "group"] == myGroup) {
                        s.value = false;
                        if (s[$ "onChange"] != undefined) s.onChange(false, s);
                    }
                }
            }
        }
        
        self.onChange(self.value, self);
        global.UI.requestRedraw();
        return true;
    });
}
