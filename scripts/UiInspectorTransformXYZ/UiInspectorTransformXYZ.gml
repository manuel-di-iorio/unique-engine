function UiInspectorTransformXYZ(style = {}, props = {}): UiNode(style, props) constructor {
    self.onBlur = props[$ "onBlur"];
    self.valueGetter = props[$ "valueGetter"];
    
    var _onBlur = function() {
       self.onBlur([ real(self.X.value), real(self.Y.value), real(self.Z.value) ]);
    };
    
    var _textStyle = { width: "29%", height: 25 };
    self.X = new UiTextbox(_textStyle, { label: "X", format: "float", onBlur: _onBlur, negative: true });
    self.Y = new UiTextbox(_textStyle, { label: "Y", format: "float", onBlur: _onBlur, negative: true });
    self.Z = new UiTextbox(_textStyle, { label: "Z", format: "float", onBlur: _onBlur, negative: true });
    
    self.add(self.X, self.Y, self.Z);
    
    // Cached previous values to avoid string() allocation every frame
    self.__lastVx = undefined;
    self.__lastVy = undefined;
    self.__lastVz = undefined;
    
    self.onStep(function() {
        if (self.valueGetter != undefined) {
            var values = self.valueGetter();
            if (values != undefined && is_array(values)) {
                var vx = values[VEC3.x], vy = values[VEC3.y], vz = values[VEC3.z];
                if (!self.X.Input.focused && self.__lastVx != vx) { self.__lastVx = vx; self.X.value = string(vx); }
                if (!self.Y.Input.focused && self.__lastVy != vy) { self.__lastVy = vy; self.Y.value = string(vy); }
                if (!self.Z.Input.focused && self.__lastVz != vz) { self.__lastVz = vz; self.Z.value = string(vz); }
            }
        }
    });
}
