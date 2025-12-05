/**
 * Directional light - light that is emitted from a specific direction.
 * Similar to the sun - rays are parallel and position doesn't affect the lighting,
 * but it does affect shadow camera placement.
 * 
 * Follows Three.js pattern:
 * - Has a position (where the light is)
 * - Has a target Object3D (where it points to)
 * - Direction is calculated as normalized vector from position to target.position
 */
function UeDirectionalLight(data = {}): UeLight(data) constructor {
    lightType = "DirectionalLight";
    
    // Target is an Object3D that the light points at (default: origin)
    target = new UeObject3D();
    
    // Shadow configuration
    shadow = new UeDirectionalLightShadow(data[$ "shadow"] ?? {});
    
    /**
     * Gets the current light direction (normalized vector from position to target).
     * This is recalculated each time to reflect any changes in position or target.
     * @returns {Struct.UeVector3} Normalized direction vector
     */
    function getDirection() {
        gml_pragma("forceinline");
        return global.UE_DUMMY_VECTOR3.copy(target.position).sub(position).normalize();
    }
}
