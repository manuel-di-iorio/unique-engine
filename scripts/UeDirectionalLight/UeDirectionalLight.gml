/**
 * Directional light - light that is emitted from a specific direction.
 * Similar to the sun - rays are parallel and position doesn't affect the lighting,
 * but it does affect shadow camera placement.
 * 
 * Notes:
 * - Has a position (where the light is)
 * - Has a target Object3D (where it points to)
 * - Direction is calculated as normalized vector from position to target.position
 */
function UeDirectionalLight(color = c_white, intensity = 1, data = {}): UeLight(data) constructor {
    lightType = "DirectionalLight"; 
    isDirectionalLight = true;
    setColor(color);
    self.intensity = intensity;
    
    // Target is an Object3D that the light points at (default: origin)
    target = new UeObject3D({ x: data[$ "xt"] ?? 0, y: data[$ "yt"] ?? 0, z: data[$ "zt"] ?? 0 });
    
    // Shadow configuration
    shadow = new UeDirectionalLightShadow(data[$ "shadow"] ?? {});
    
    /**
     * Gets the current light direction (normalized vector from position to target).
     * This is recalculated each time to reflect any changes in position or target.
     * @params {Array} v - Output vector (vec3)
     * @returns {Array} Normalized direction vector (vec3)
     */
    function getDirection(v = global.UE_VEC3_TEMP0) {
        gml_pragma("forceinline");
        vec3_copy(v, target.position);
        vec3_sub(v, position);
        vec3_normalize(v);
        return v;
    }
}
