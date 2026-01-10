---
sidebar_position: 2
---

The `UeBufferLoader` class provides functionality to deserialize scenes or meshes from binary buffers created by `UeBufferExporter`.

It reconstructs object hierarchies, resolves UUID references, and rebuilds the complete scene graph with all dependencies.

:::caution
This loader has not been tested recently and may not work correctly.
:::

### Constructor
```js
new UeBufferLoader()
```

### Properties

| Property          | Type      | Default | Description                             |
| ----------------- | --------- | ------- | --------------------------------------- |
| `isBufferLoader`  | `boolean` | `true`  | Identifies this object as a buffer loader |
| `type`            | `string`  | `BufferLoader` | Object type                        |
| `name`            | `string`  | undefined | Object name (optional)                |
| `cache`           | `object`  | Internal cache | Temporary storage for object resolution |

## 🧩 Methods

```js
load(fname, isCompressed = true, resetCache = true)
```
Loads and reconstructs scene objects from a binary buffer file.

### Data parameters

| Parameter      | Type      | Default | Description                                      |
| -------------- | --------- | ------- | ------------------------------------------------ |
| `fname`        | `string`  | **required** | File path to the buffer file to load         |
| `isCompressed` | `boolean` | `true`  | Whether the buffer file is compressed           |
| `resetCache`   | `boolean` | `true`  | Whether to clear the internal cache before loading |

### Returns

| Type     | Description                                    |
| -------- | ---------------------------------------------- |
| `object` | Contains `objects`, `textures`, and `materials` arrays |

**Return Structure:**
```js
{
    objects: [],     // Array of root scene objects (meshes, lights)
    textures: {},    // Map of loaded textures by UUID
    materials: {}    // Map of loaded materials by UUID
}
```

---

## 🔧 Internal Logic

**Loading Process**

The loader works in three phases:

1. **Buffer Reading Phase** - Sequentially reads and parses objects from the buffer:
   - `VertexFormat` - Vertex layout definitions
   - `Geometry` - Geometry data with vertex buffers
   - `Texture` - Image data and sampler settings
   - `Material` - Shader properties and texture references
   - `Mesh` - Scene graph nodes with transform data
   - `Light` - Lighting objects

2. **Resolution Phase** - Resolves UUID references between objects:
   - Geometries → Vertex formats
   - Materials → Textures
   - Meshes → Geometries and materials

3. **Hierarchy Reconstruction** - Rebuilds the scene graph structure:
   - Links parent-child relationships
   - Restores transform hierarchies
   - Returns root objects and resource maps

**Caching System**

The internal cache stores objects during loading:
- `formats` - Vertex format objects
- `geometries` - Geometry objects  
- `textures` - Texture objects
- `materials` - Material objects
- `meshesFlat` - Flat array of all meshes
- `meshesFlatMap` - UUID-to-mesh mapping
- `lights` - Light objects

**Texture Reconstruction**

For textures with sprite data:
- Reconstructs sprites from buffer data
- Creates temporary surfaces for pixel data
- Generates sprite assets and saves them as PNG files
- Links textures to the reconstructed sprites

---

## 🧠 Notes

- The loader expects buffers created by `UeBufferExporter`
- Compression/decompression is handled automatically based on the `isCompressed` parameter
- UUID references are resolved after all objects are loaded to handle forward references
- Transform data is fully reconstructed including position, rotation, scale, and up vectors
- Shader references are resolved by asset name when available
- The cache can be preserved between loads for incremental loading scenarios
- Vertex buffers are reconstructed from the original vertex format definitions
