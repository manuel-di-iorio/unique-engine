function UeAmbientLight(_color = c_white, data = {}): UeLight(data) constructor {
    lightType = "AmbientLight";
    setColor(_color);
}