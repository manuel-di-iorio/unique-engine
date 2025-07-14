---
sidebar_position: 2
---

A simple line mesh class that renders a continuous line strip using provided geometry and material.
Useful for drawing lines or wireframes in 3D space.

### Constructor
```js
new UeLine(geometry = undefined, material = undefined, data = {})
```

> Inherits from [UeMesh](/docs/reference/objects/UeMesh)

### Parameters

| Name     | Type                  | Default                     | Description                          |
| -------- | --------------------- | --------------------------- | ------------------------------------ |
| geometry | `UeBufferGeometry`    | `new UeBufferGeometry()`    | Geometry defining the line vertices  |
| material | `UeLineBasicMaterial` | `new UeLineBasicMaterial()` | Material used to render the line     |
| data     | `Object`              | `{}`                        | Additional data passed to base class |


### Properties

| Property    | Type                  | Description                                                |
| ----------- | --------------------- | ---------------------------------------------------------- |
| `isLine`    | `boolean`             | Flag identifying this as a line primitive                  |
| `primitive` | `string`              | Primitive type, here `"pr_linestrip"` for continuous lines |
| `geometry`  | `UeBufferGeometry`    | Geometry data for line vertices                            |
| `material`  | `UeLineBasicMaterial` | Material used for rendering the line                       |
