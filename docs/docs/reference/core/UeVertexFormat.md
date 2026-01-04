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
const format = new UeVertexFormat().position().normal().uv().color().build();
```

### Properties

| Property          | Type         | Default          | Description                            |
| -------------     | ------------ | -------          | ----------------------------           |
| `isVertexFormat`  | `boolean`    | true             | Indicates that this is a vertex format |
| `type`            | `string`     | `"VertexFormat"` | Object type                            |
| `name`            | `string`     | ""               | Object name (optional)                 |
| `uuid`            | `string`     |                  | Resource UUID                          |

## 🧩 Methods
```js
position()
```

Adds a 3D position attribute.

```js
normal()
```
Adds a normal vector attribute.

```js
tangent()
```
Adds a tangent vector attribute (float4).

```js
uv()
```
Adds a UV texture coordinate attribute.

```js
color()
```
Adds a vertex color attribute.

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

### Default formats in Unique Engine:

```js
global.UE_DEFAULT_VERTEX_FORMAT = new UeVertexFormat().position().normal().uv().color().build();
global.UE_ASSIMP_VERTEX_FORMAT = new UeVertexFormat().position().normal().tangent().uv().color().build();
global.UE_POSITION_UV_VFORMAT = new UeVertexFormat().position().uv().build();
```
