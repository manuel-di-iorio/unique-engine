---
sidebar_position: 3
title: UeGeometry
---

A geometry class representing a 3D geometry, optimized for GPU rendering.  
Manages vertex data, index buffers, and provides methods to build, freeze, and dispose the vertex buffer.  
Includes support for bounding volumes (bounding box and bounding sphere).

### Constructor
```js
new UeGeometry(data = {})
```

### Data parameters

| Key        | Type             | Default                           | Description                                         |
| ---------- | ---------------- | --------------------------        | ---------------------------------------             |
| `position` | `array`          | `undefined`                       | Array of vertex positions [x,y,z, x,y,z, ...]      |
| `normal`   | `array`          | `undefined`                       | Array of vertex normals [nx,ny,nz, ...]             |
| `uv`       | `array`          | `undefined`                       | Array of texture coordinates [u,v, ...]             |
| `color`    | `array`          | `undefined`                       | Array of vertex colors [col, alpha, col, alpha, ...]|
| `index`    | `array` / `null` | `undefined`                       | Optional index buffer for reusing verts             |
| `format`   | `VertexFormat`   | `global.UE_VFORMAT_PNUC` | Vertex layout format                                |
| `canFreeze`| `boolean`        | `true`                            | Whether to freeze the vertex buffer after the build |
| `boundingBox`                 | `UeBox3`                          | Axis-aligned bounding box                           |
| `boundingSphere`              | `UeSphere`                        | Bounding sphere                                     |

### Properties

| Property           | Type                   | Description                                                 |
| ------------------ | ---------------------- | ----------------------------------------------------------- |
| `isGeometry`       | `boolean`              | Flag indicating this is a geometry                          |
| `type`             | `string`               | Type identifier `"Geometry"`                                |
| `uuid`             | `string`               | Unique identifier                                           |
| `name`             | `string`               | Optional name                                               |
| `position`         | `Array`                | Vertex position data array                                  |
| `normal`           | `Array`                | Vertex normal data array                                    |
| `uv`               | `Array`                | Vertex UV data array                                        |
| `color`            | `Array`                | Vertex color data array                                     |
| `index`            | `Array` or `undefined` | Optional index array                                        |
| `format`           | `Object`               | Vertex format descriptor                                    |
| `vb`               | `object`               | Vertex buffer handle                                        |
| `canFreeze`        | `boolean`              | If true, allows freezing the vertex buffer for optimization |
| `boundingBox`      | `UeBox3`               | Axis-aligned bounding box                                   |
| `boundingSphere`   | `UeSphere`             | Bounding sphere                                             |


## Methods

| Method                             | Returns  | Description                                                                 |
| ---------------------------------- | -------- | --------------------------------------------------------------------------- |
| `build()`                          | `self`   | Builds the vertex buffer from the current attributes and vertex format      |
| `freeze()`                         | `self`   | Freezes the vertex buffer to optimize usage                                 |
| `dispose()`                        | `self`   | Deletes the vertex buffer and releases GPU resources                        |
| `computeBoundingBox()`             | `self`   | Computes the bounding box from the current vertex positions                 |
| `computeBoundingSphere()`          | `self`   | Computes the bounding sphere from the current vertex positions              |
| `applyMatrix(matrix)`              | `self`   | Applies the matrix transform to the geometry vertices                       |
| `merge(geometries)`                | `UeGeometry` | Returns a new geometry by merging an array of geometries. They must share the same format. |
| `toJSON()`                         | `struct` | Returns an object representing this entity's properties.                    |
| `fromJSON(data)`                   | `self`   | Loads geometry properties from a JSON object.                               |
| `export(fname)`                    | `self`   | Exports only the vertex buffer to a file.                                   |
| `import(fname)`                    | `self`   | Loads the vertex buffer data from a previously exported file.               |


## Notes

The geometric data is stored in separate flat arrays (e.g., `position`, `normal`, `uv`) rather than vertex structs.

If `index` is provided, it must be an array of indices pointing into these attribute arrays.

You can define custom vertex attributes using `.format.custom(name, type)` and provide the data as an array directly on the geometry instance using the custom attribute name.
