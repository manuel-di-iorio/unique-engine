---
sidebar_position: 2
---

The `UeVertexFormat` class defines the layout of vertex data for a `UeBufferGeometry`. It acts as a chainable builder for setting attributes like position, normal, UV, color, and custom fields.

### Constructor

```js
new UeVertexFormat()
```

### 🛠️ Usage Example

```js
const format = new UeVertexFormat().position().normal().uv().color().build();
```

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

### Default format in Unique Engine:

```js
global.UE_DEFAULT_VERTEX_FORMAT = new UeVertexFormat().position().normal().uv().color().build();
```
