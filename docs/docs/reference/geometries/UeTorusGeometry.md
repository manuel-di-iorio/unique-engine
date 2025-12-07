---
sidebar_position: 9
---

import Geometry from '@site/static/img/geometries/torus.jpg';

<img src={Geometry} width="250" />

> Inherits from [UeBufferGeometry](/docs/reference/core/UeBufferGeometry)

Represents a torus (donut) geometry.

```js
new UeTorusGeometry(radius = 40, tubeRadius = 10, data = {})
```

## Constructor parameters

| Parameter        | Type     | Default   | Description                               |
| ---------------- | -------- | --------- | ----------------------------------------- |
| `radius`         | `number` | `40`      | Major radius of the torus                   |
| `tubeRadius`     | `number` | `10`      | Minor radius (tube radius)                |
| `data.color`     | `Color`  | `c_white` | Optional base color for vertices          |
| `data.alpha`     | `number` | `1`       | Optional base alpha for vertices          |
| `data.radialSegments` | `number` | `16`      | Number of segments around the tube          |
| `data.tubularSegments` | `number` | `32`      | Number of segments along the tube           |
| `data.arc`       | `number` | `2 * pi`  | Total arc length in radians               |
| `data.arcOffset` | `number` | `0`       | Starting angle offset in radians          |
