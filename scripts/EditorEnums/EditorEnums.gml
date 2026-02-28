/// @description Editor enumerations - Centralizes all editor constants to avoid magic strings

/// Asset types used throughout the editor
enum ASSET_TYPE {
    Folder,
    Texture,
    Material,
    Mesh,
    Object3D,
    Bone,
    Scene,
    Light,
    PointLight,
    DirectionalLight,
    Camera
}

/// Maps ASSET_TYPE enum values to their string representation (for serialization/display)
global.__ASSET_TYPE_NAMES = array_create(11);
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Folder] = "Folder";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Texture] = "Texture";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Material] = "Material";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Mesh] = "Mesh";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Object3D] = "Object3D";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Bone] = "Bone";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Scene] = "Scene";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Light] = "Light";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.PointLight] = "PointLight";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.DirectionalLight] = "DirectionalLight";
global.__ASSET_TYPE_NAMES[ASSET_TYPE.Camera] = "Camera";

/// Lookup from string name to ASSET_TYPE enum value (for deserialization)
global.__ASSET_TYPE_FROM_STRING = {};
global.__ASSET_TYPE_FROM_STRING[$ "Folder"] = ASSET_TYPE.Folder;
global.__ASSET_TYPE_FROM_STRING[$ "Texture"] = ASSET_TYPE.Texture;
global.__ASSET_TYPE_FROM_STRING[$ "Material"] = ASSET_TYPE.Material;
global.__ASSET_TYPE_FROM_STRING[$ "Mesh"] = ASSET_TYPE.Mesh;
global.__ASSET_TYPE_FROM_STRING[$ "Object3D"] = ASSET_TYPE.Object3D;
global.__ASSET_TYPE_FROM_STRING[$ "Bone"] = ASSET_TYPE.Bone;
global.__ASSET_TYPE_FROM_STRING[$ "Scene"] = ASSET_TYPE.Scene;
global.__ASSET_TYPE_FROM_STRING[$ "Light"] = ASSET_TYPE.Light;
global.__ASSET_TYPE_FROM_STRING[$ "PointLight"] = ASSET_TYPE.PointLight;
global.__ASSET_TYPE_FROM_STRING[$ "DirectionalLight"] = ASSET_TYPE.DirectionalLight;
global.__ASSET_TYPE_FROM_STRING[$ "Camera"] = ASSET_TYPE.Camera;

/// Convert ASSET_TYPE enum to string
/// @param {Real} assetType The ASSET_TYPE enum value
/// @returns {String}
function asset_type_to_string(assetType) {
    gml_pragma("forceinline");
    return global.__ASSET_TYPE_NAMES[assetType];
}

/// Convert string to ASSET_TYPE enum
/// @param {String} str The asset type string
/// @returns {Real} ASSET_TYPE enum value, or undefined if not found
function asset_type_from_string(str) {
    gml_pragma("forceinline");
    return global.__ASSET_TYPE_FROM_STRING[$ str];
}

/// Editor tool modes
enum EDITOR_TOOL {
    View,
    Move,
    Rotate,
    Scale
}

/// Maps EDITOR_TOOL enum values to their string representation
global.__EDITOR_TOOL_NAMES = array_create(4);
global.__EDITOR_TOOL_NAMES[EDITOR_TOOL.View] = "view";
global.__EDITOR_TOOL_NAMES[EDITOR_TOOL.Move] = "move";
global.__EDITOR_TOOL_NAMES[EDITOR_TOOL.Rotate] = "rotate";
global.__EDITOR_TOOL_NAMES[EDITOR_TOOL.Scale] = "scale";

/// Convert EDITOR_TOOL enum to string (for TransformControls mode)
/// @param {Real} tool The EDITOR_TOOL enum value
/// @returns {String}
function editor_tool_to_string(tool) {
    gml_pragma("forceinline");
    return global.__EDITOR_TOOL_NAMES[tool];
}
