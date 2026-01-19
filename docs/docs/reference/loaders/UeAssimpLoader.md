---
sidebar_position: 1
---

# UeAssimpLoader

The `UeAssimpLoader` is the primary tool for importing complex 3D models into the Unique Engine. It leverages the Assimp (Open Asset Import Library) extension to support a vast array of 3D file formats, including GLTF, OBJ, FBX, 3DS, DAE, and more.

> STATUS: **BETA** - While robust, some complex material configurations or specific format quirks may require manual adjustment after loading.

---

## Constructor

```js
new UeAssimpLoader(data = {})
```

### Parameters
- `data`: (Optional) Initialization settings:
    - `canFreeze`: (Boolean, default: `true`) If set to `true`, the loader will automatically call `vertex_freeze()` on all loaded geometries. This significantly improves rendering performance but makes the vertex buffer read-only (which is the standard for static or skinned meshes).
    - `matrixAutoUpdate`: (Boolean, default: `true`) If set to `true`, all objects, meshes, and bones created by the loader will have `matrixAutoUpdate` enabled. Setting this to `false` can improve performance for static scenes where you manually manage matrix updates.

---

## Methods

| Method | Returns | Description |
| :--- | :--- | :--- |
| `load(filename)` | `struct` | Synchronously reads a file and returns the processed scene data. |
| `dispose()` | `self` | Frees the internal Assimp importer resources. |

### `load(filename)` Result Struct
The `load` method returns a struct containing all components of the 3D scene:

| Property | Type | Description |
| :--- | :--- | :--- |
| `root` | `UeObject3D` | The root node of the loaded scene hierarchy. |
| `materials` | `struct` | A map of `UeMeshStandardMaterial` instances, indexed by their name in the model. |
| `animations` | `struct` | A map of `UeAnimation` objects, indexed by animation name. |
| `textures` | `array` | A list of all unique `UeTexture` objects loaded for the model. |
| `skeleton` | `UeSkeleton` | (Optional) The skeleton object if the model contains skinning/bones. |

---

## Code Example

```js
// Initialize the loader
var loader = new UeAssimpLoader();

// Load a model (e.g., a GLTF file)
var modelData = loader.load("models/character.gltf");

// Add the model to your scene
scene.add(modelData.root);

// Access a specific animation by name
var walkAnim = modelData.animations[$ "Walk"];

// Access a material to change its properties
var bodyMat = modelData.materials[$ "Body_Material"];
bodyMat.roughness = 0.5;

// Clean up the loader when done (optional if you plan to load more)
loader.dispose();
```

---

## 🧠 Technical Notes

- **Vertex Formats**: 
    - Models with bones use `global.UE_VFORMAT_PNUTCB` (Position, Normal, UV, Tangent, Color, Bone Indices/Weights).
    - Static models use `global.UE_VFORMAT_PNUTC`.
- **Hierarchy Management**: The loader preserves the original node hierarchy of the source file. Bones are automatically converted from `UeObject3D` to `UeBone` during skeleton construction.
- **PBR Materials**: Materials are imported as `UeMeshStandardMaterial` by default, mapping textures like Diffuse, Normals, Metalness, and Roughness to the corresponding PBR channels.
- **Winding Order**: The loader automatically handles common import issues like UV flipping and winding order synchronization for GameMaker's coordinate system.
