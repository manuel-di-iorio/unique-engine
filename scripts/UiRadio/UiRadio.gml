function UiRadio(style = {}, props = {}) : UiCheckbox(style, props) constructor {
    self.variant = "radio";
    setName(props[$ "name"] ?? "UiRadio");
}
