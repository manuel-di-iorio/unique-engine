/**
 * Base class for light shadow controllers.
 * Provides common properties and helper methods shared by directional and point light shadows.
 */
function UeLightShadow(data = {}) constructor {
    mapSize = {
        width: data[$ "mapWidth"] ?? 1024, 
        height: data[$ "mapHeight"] ?? 1024 
    };
}
