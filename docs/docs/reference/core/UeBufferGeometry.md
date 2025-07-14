---
sidebar_position: 3
---

A geometry class representing a buffer geometry, optimized for GPU rendering.  
Manages vertex data, index buffers, and provides methods to build, freeze, and dispose the vertex buffer.  
Includes support for bounding volumes (bounding box and bounding sphere).

### Constructor
```js
new UeBufferGeometry(data = {})
```

### Data parameters

| Key        | Type             | Default                           | Description                                         |
| ---------- | ---------------- | --------------------------        | ---------------------------------------             |
| `vertices` | `array`          | `[]`                              | Array of vertex data                                |
| `index`    | `array` / `null` | `undefined`                       | Optional index buffer for reusing verts             |
| `format`   | `VertexFormat`   | `global.UE_DEFAULT_VERTEX_FORMAT` | Vertex layout format                                |
| `canFreeze`| `boolean`        | `true`                            | Whether to freeze the vertex buffer after the build |
| `boundingBox`                 | `UeBox3`                          | Axis-aligned bounding box                           |
| `boundingSphere`              | `UeSphere`                        | Bounding sphere                                     |

### Properties

| Property           | Type                   | Description                                                 |
| ------------------ | ---------------------- | ----------------------------------------------------------- |
| `isBufferGeometry` | `boolean`              | Flag indicating this is a buffer geometry                   |
| `type`             | `string`               | Type identifier `"BufferGeometry"`                          |
| `uuid`             | `string`               | Unique identifier                                           |
| `name`             | `string`               | Optional name                                               |
| `vertices`         | `Array`                | Vertex data array                                           |
| `index`            | `Array` or `undefined` | Optional index array                                        |
| `format`           | `Object`               | Vertex format descriptor                                    |
| `vb`               | `object`               | Vertex buffer handle                                        |
| `canFreeze`        | `boolean`              | If true, allows freezing the vertex buffer for optimization |
| `boundingBox`      | `UeBox3`               | Axis-aligned bounding box                                   |
| `boundingSphere`   | `UeSphere`             | Bounding sphere                                             |


## Methods

| Method                             | Returns  | Description                                                                 |
| ---------------------------------- | -------- | --------------------------------------------------------------------------- |
| `build()`                          | `self`   | Builds the vertex buffer from the current vertices and vertex format        |
| `freeze()`                         | `self`   | Freezes the vertex buffer to optimize usage                                 |
| `dispose()`                        | `self`   | Deletes the vertex buffer and releases GPU resources                        |
| `computeBoundingBox()`             | `self`   | Computes the bounding box from the current vertex positions                 |
| `computeBoundingSphere()`          | `self`   | Computes the bounding sphere from the current vertex positions              |


## Notes

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
