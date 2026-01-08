---
sidebar_position: 2
---

The `UeVertexFormat` class defines the layout of vertex data for a `UeGeometry`. It acts as a chainable builder for setting attributes like position, normal, UV, color, and custom fields.

### Constructor

```js
new UeVertexFormat()
```

### 🛠️ Usage Example

```js
// Create the standard PNUTC format (Position, Normal, UV, Tangent, Color)
const format = new UeVertexFormat().position().normal().uv().tangent().color().build();
```

### Global Formats

Unique Engine provides pre-defined global vertex formats for common use cases:

- `global.UE_VFORMAT_PNUTC`: Standard format with Position, Normal, UV, Tangent (float4), and Color.
- `global.UE_VFORMAT_PNUC`: Format with Position, Normal, UV, and Color (no tangents).
- `global.UE_VFORMAT_PU`: Minimal format with Position and UV.

---

## 🧩 Methods

```js
position()
```

Adds a 3D position attribute (`vertex_format_add_position_3d`).

```js
normal()
```

Adds a normal vector attribute (`vertex_format_add_normal`).

```js
uv()
```

Adds a UV texture coordinate attribute (`vertex_format_add_texcoord`).

```js
tangent()
```

Adds a tangent vector attribute as a custom `float4` (XYZ for direction, W for handedness). This is required for PBR materials and normal mapping.

```js
color()
```

Adds a vertex color attribute (`vertex_format_add_color`).

```js
custom(name, type)
```
Adds a custom vertex attribute.

- name – Name of the attribute, for reference
- type – Type of the attribute (e.g. vertex_type_float2)

```js
build()
```
Finalizes the vertex format and returns the current object. Internally calls `vertex_format_begin()` and `vertex_format_end()`.

```js
dispose()
```
Cleanup the vertex format resource

```js
toJSON()
```

Returns an object representing this entity's properties. Not all props may be included.
