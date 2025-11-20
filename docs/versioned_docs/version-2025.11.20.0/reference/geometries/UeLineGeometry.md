---
sidebar_position: 8
---

import Geometry from '@site/static/img/geometries/lineSegments.png';

<img src={Geometry} width="400" />

A chain of vertices connected together, forming a polyline.

## Constructor

```js
new UeLineSegmentsGeometry(data = {})
```

> Inherits from [UeLineGeometry](/docs/reference/geometries/UeLineGeometry)

### Data properties

| Property                 | Type      | Description                               |
| ------------------------ | --------- | ----------------------------------------- |
| `color`                  | `Color`   | Line color                                |
| `alpha`                  | `number`  | Line transparency                         |

## Properties

| Property                 | Type      | Description                               |
| ------------------------ | --------- | ----------------------------------------- |
| `color`                  | `Color`   | Line color                                |
| `alpha`                  | `number`  | Line transparency                         |


## Methods

| Method                  | Returns | Description                                                               |
| ----------------------- | ------- | ------------------------------------------------------------------------- |
| `setPositions(array)`   | `self`  | Populates the geometry with 3D vertices. Each 3 values represent x, y, z. |
| `setColors(array)`      | `self`  | Sets the per-vertex color. Each 3 values represent r, g, b.               |
| `setFromPoints(points)` | `self`  | Fills geometry with an array of `UeVector3` or `UeVector2` points.        |
| `fromLine(line)`        | `self`  | Copies vertex data from a `UeLine` object (non-indexed).                  |
