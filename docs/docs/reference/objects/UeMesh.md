---
sidebar_position: 1
---

The `UeMesh` class is a renderable object in Unique Engine. It combines a geometry (vertex buffer) with a material and is placed in the scene graph via its transformation.

## Constructor
```js
new UeMesh(geometry, material = UeMeshStandardMaterial(), data = {})
```

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

## Data parameters

| Key         | Type                  | Default                    | Description                          |
| ----------- | --------------------- | -------------------------- | -----------------------------------  |
| `primitive` | `number`              | `pr_trianglelist`          | GPU primitive mode                   |

## Properties

| Property    | Type               | Default                    | Description                           |
| ----------- | ---------          | -------                    | -----------------------------------   |
| `isMesh`    | `boolean`          | `true`                     | Identifies this object as a mesh      |
| `type`      | `string`           | `"Mesh"`                   | Object type                           |
| `geometry`  | `UeBufferGeometry` | **required**               | The geometry (vertex data)            |
| `material`  | `UeMaterial`       | `UeMeshStandardMaterial()` | The material to use                   |
| `primitive` | `number`           | `pr_trianglelist`          | GPU primitive mode                    |
| `name`      | `string`           | ""                         | Object name (empty string by default) |

## Methods

| Method                           | Returns | Description                                                                                                |
| -------------------------------- | ------- | ------------------------------------------------------------------------------------------------------     |
| `raycast(raycaster, intersects)` | `self`  | Tests the ray from `raycaster` against this object's bounding box/sphere and appends hits to `intersects`. |
| `toJSON()`                       | `struct`| Returns an object representing this entity's properties. Not all props may be included                     |
