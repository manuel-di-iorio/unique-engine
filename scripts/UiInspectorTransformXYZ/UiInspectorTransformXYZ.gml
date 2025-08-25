function UiInspectorTransformXYZ(style = {}, props = {}): UiNode(style, props) constructor {
    self.onBlur = props[$ "onBlur"];
    self.valueGetter = props[$ "valueGetter"];
    
    var _onBlur = function() {
       self.onBlur([ real(self.X.value), real(self.Y.value), real(self.Z.value) ]);
    };
    
    var _textStyle = { width: "29%", height: 25 };
    self.X = new UiTextbox(_textStyle, { label: "X", format: "float", onBlur: _onBlur });
    self.Y = new UiTextbox(_textStyle, { label: "Y", format: "float", onBlur: _onBlur });
    self.Z = new UiTextbox(_textStyle, { label: "Z", format: "float", onBlur: _onBlur });
    
    self.add(self.X, self.Y, self.Z);
    
    function onStep() {
        if (self.valueGetter != undefined) {
            var values = self.valueGetter();
            if (!self.X.Input.focused) self.X.value = string(values.x);
            if (!self.Y.Input.focused) self.Y.value = string(values.y);
            if (!self.Z.Input.focused) self.Z.value = string(values.z);
        }
    }
}