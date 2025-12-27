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
    
    self.onStep(function() {
        if (self.valueGetter != undefined) {
            var values = self.valueGetter();
            if (!self.X.Input.focused) self.X.value = string(values[VEC3.x]);
            if (!self.Y.Input.focused) self.Y.value = string(values[VEC3.y]);
            if (!self.Z.Input.focused) self.Z.value = string(values[VEC3.z]);
        }
    });
}
