---
sidebar_position: 1
---

The `UeBufferExporter` class provides functionality to serialize scenes or meshes into binary buffers for storage or network transmission.

It recursively processes object hierarchies, compiles their data, and optionally compresses the resulting buffer.

### Constructor
```js
new UeBufferExporter()
```

### Properties

| Property          | Type      | Default | Description                             |
| ----------------- | --------- | ------- | --------------------------------------- |
| `isBufferExporter`| `boolean` | `true`  | Identifies this object as a buffer exporter |
| `type`            | `string`  | `BufferExporter` | Object type                      |
| `name`            | `string`  | undefined | Object name (optional)                |

## 🧩 Methods

```js
parse(obj, compress = true, compileSprites = true)
```
Exports a scene or mesh object to a binary buffer.

### Parameters

| Parameter       | Type      | Default | Description                                    |
| --------------- | --------- | ------- | ---------------------------------------------- |
| `obj`           | `UeObject3D` | **required** | The scene or mesh object to export         |
| `compress`      | `boolean` | `true`  | Whether to compress the resulting buffer       |
| `compileSprites`| `boolean` | `true`  | Whether to compile sprite data in the export   |

### Returns

| Type     | Description                                    |
| -------- | ---------------------------------------------- |
| `buffer` | A GameMaker buffer containing the serialized data |

---

## 🔧 Internal Logic

**Compilation Process**

The exporter works in two phases:

1. **Compilation Phase** - Recursively traverses the object hierarchy and builds a compilation structure containing:
   - Serialized JSON payloads for each object
   - Cached objects to avoid duplication
   - Total buffer size calculation
   - Extra binary data contexts

2. **Buffer Building Phase** - Writes all compiled data to a binary buffer in sequence

**Supported Object Types**

- `BufferGeometry` - Includes vertex format compilation
- `Material` - Includes all associated textures
- `Mesh` - Includes geometry and material dependencies
- All `UeObject3D` descendants with children

**Compression**

When `compress` is enabled, the final buffer is compressed using GameMaker's `buffer_compress()` function.

---

## 🧠 Notes

- Objects are cached by UUID to prevent duplicate serialization
- The exporter calls each object's `_compileData()` method to gather serializable data
- Extra binary data (like vertex buffers) is handled via `_compileBufferExtra()` callbacks
- Scenes (`isScene` objects) are treated as root containers and not serialized themselves
- The resulting buffer can be used for save/load systems or network transmission
