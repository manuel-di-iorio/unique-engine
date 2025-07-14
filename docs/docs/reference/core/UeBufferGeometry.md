---
sidebar_position: 3
---

The `UeBufferGeometry` class represents a 3D geometry made of vertices and optional indices. It inherits from `UeObject3D`, and is meant to be rendered by `UeMesh`.

### Constructor
```js
new UeBufferGeometry(data = {})
```

### Data parameters

| Key        | Type             | Default                           | Description                             |
| ---------- | ---------------- | --------------------------        | --------------------------------------- |
| `vertices` | `array`          | `[]`                              | Array of vertex data                    |
| `index`    | `array` / `null` | `undefined`                       | Optional index buffer for reusing verts |
| `format`   | `VertexFormat`   | `global.UE_DEFAULT_VERTEX_FORMAT` | Vertex layout format                    |
| `canFreeze`| `boolean`        | `true`                            | Whether to freeze the vertex buffer after the build |

### Properties

| Property          | Type         | Default   | Description                              |
| -------------     | ------------ | -------   | ------------------------------           |
| `isBufferGeometry`| `boolean`    | true      | Indicates that this is a buffer geometry |
| `type`            | `string`     | `"BufferGeometry"` | Object type                               |
| `name`            | `string`     | undefined | Object name (optional)                   |
| `uuid`            | `string`     |            Resource UUID                            |

## 🧩 Methods

```js
build()
```
Compiles the vertex buffer using the current vertices, index, and format. You must call this before rendering.


```js
freeze()
```
Freeze the vertex buffer. Call after .build() when you completed building the geometry.
Because it resides in VRAM, a frozen vertex buffer can be submitted to the shader faster than a normal, dynamic buffer.

```js
dispose()
```
Destroys the internal vertex buffer. Call this when the geometry is no longer needed.

## 🧠 Notes
`vertices` is an array of vertex structs. Their properties must match the format set in .format.

If `index` is provided, it must be an array of indices pointing into vertices.

You can define custom vertex attributes using .format.custom(name, type) and pass them under a custom field:

```js
new UeVertexFormat()
  .position()
  .custom("foo", vertex_type_float2)
  .build();

vertices = [
  { x: 0, y: 0, z: 0, custom: { foo: [1.0, 0.5] } }
];
```
