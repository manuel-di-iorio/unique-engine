---
sidebar_position: 7
---

import Geometry from '@site/static/img/geometries/lineSegments.png';

<img src={Geometry} width="400" />

Represents a series of individual line segments, each defined by a pair of 3D points. This class is useful for drawing disconnected line pairs, such as wireframes or outlines.

## Constructor

```js
new UeLineSegmentsGeometry(data = {})
```

> Inherits from [UeBufferGeometry](/docs/reference/core/UeBufferGeometry)

### Data properties

| Property                 | Type      | Description                               |
| ------------------------ | --------- | ----------------------------------------- |
| `color`                  | `Color`   | Lines color                               |
| `alpha`                  | `number`  | Lines transparency                        |

## Properties

| Property                 | Type      | Description                               |
| ------------------------ | --------- | ----------------------------------------- |
| `color`                  | `Color`   | Lines color                               |
| `alpha`                  | `number`  | Lines transparency                        |


## Methods

| Method                | Returns | Description                                                                                          |
| --------------------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `setPositions(array)` | `self`  | Populates the geometry with vertex pairs. Each 6 values represent two 3D points (x1,y1,z1,x2,y2,z2). |
| `setColors(array)`    | `self`  | Sets the per-vertex color for each segment. Every 6 values represent RGB for the two points.         |
| `fromMesh(mesh)`      | `self`  | Extracts vertex pairs from a `UeMesh` geometry (non-indexed)                                         |
