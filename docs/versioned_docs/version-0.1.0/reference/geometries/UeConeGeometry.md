---
sidebar_position: 9
---

import Geometry from '@site/static/img/geometries/cone.jpg';

<img src={Geometry} width="150" />

Represents a 3D cone geometry aligned along the negative Z axis (−Z), suitable for use in directional helpers like arrows or rays.  
The cone is constructed with a circular base and a tip, and its orientation has been rotated −90° around the X axis.

This geometry is typically used for debugging or visualization of directions, such as the tip of an arrow in UeArrow


```js
new UeConeGeometry(radius = 1, height = 1, radialSegments = 32, data = {})
```

> Inherits from [UeBufferGeometry](/docs/reference/core/UeBufferGeometry)

## Constructor parameters

| Parameter        | Type     | Default   | Description                               |
| ---------------- | -------- | --------- | ----------------------------------------- |
| `radius`         | `number` | `1`       | Base radius of the cone                   |
| `height`         | `number` | `1`       | Vertical height of the cone               |
| `radialSegments` | `number` | `32`      | Number of segmented faces around the base |
| `data.color`     | `Color`  | `c_white` | Optional base color for vertices          |
| `data.alpha`     | `number` | `1`       | Optional base alpha for vertices          |
