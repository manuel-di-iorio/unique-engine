// yaw = horizontal degrees
// pitch = vertical degrees
// 0,0 = forward direction by default (0,1,0)
function UeDirectionalLight(horizontal = 0, vertical = 0, data = {}): UeLight(data) constructor {
    lightType = "DirectionalLight";
    target = new UeVector3();
    shadow = new UeDirectionalLightShadow(data[$ "shadow"] ?? {});
    
    /**
     * Sets the light direction using horizontal (yaw) and vertical (pitch) angles.
     * 
     * The direction is calculated from a base forward vector (0, 1, 0) rotated by:
     * 1. Pitch (vertical) - rotation around X axis
     * 2. Yaw (horizontal) - rotation around Z axis
     * 
     * Note: The result is stored with Y and Z swapped to match the engine's coordinate system
     * where Y is typically the depth axis and Z is up/down.
     * 
     * @param {number} horizontal - Yaw angle in degrees (0 = forward, 90 = right)
     * @param {number} vertical - Pitch angle in degrees (0 = horizontal, 90 = up)
     */
    function setDirection(horizontal = 0, vertical = 0) {
        // Base forward vector
        var xx = 0;
        var yy = 1;
        var zz = 0;
    
        // First: rotate around X (pitch)
        var y1 = yy * dcos(vertical) - zz * dsin(vertical);
        var z1 = yy * dsin(vertical) + zz * dcos(vertical);
        var x1 = xx;
    
        // Second: rotate around Z (yaw)
        var x2 = x1 * dcos(horizontal) - y1 * dsin(horizontal);
        var y2 = x1 * dsin(horizontal) + y1 * dcos(horizontal);
        var z2 = z1;
    
        // Use engine coordinate ordering: x, y, z
        target.set(x2, y2, z2);
    }
    
    setDirection(horizontal, vertical);
}
