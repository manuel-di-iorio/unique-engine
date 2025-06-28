---
sidebar_position: 4
---

The `UeMesh` class is the renderable object in Unique Engine. It combines a geometry (vertex buffer) with a material and is placed in the scene graph via its transformation.

### Constructor
```js
new UeMesh(geometry, data = {})
```

### Parameters

| Key         | Type                  | Default                    | Description                          |
| ----------- | --------------------- | -------------------------- | -----------------------------------  |
| `geometry`  | `UeBufferGeometry`    | **required**               | The geometry (vertex data)           |
| `material`  | `UeMaterial`          | `UeMeshStandardMaterial()` | The material to use                  |
| `primitive` | `number`              | `pr_trianglelist`          | GPU primitive mode (e.g. triangles)  |
