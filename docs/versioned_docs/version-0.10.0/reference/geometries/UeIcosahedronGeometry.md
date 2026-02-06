---
sidebar_position: 13
---

Represents a 3D icosahedron geometry.  
The icosahedron is a polyhedron with 20 equilateral triangular faces. By increasing the `detail` parameter, the geometry is recursively subdivided by projecting the vertices onto a sphere, transforming it into a geodesic sphere.

```js
new UeIcosahedronGeometry(radius = 1, detail = 0, data = {})
```

> Inherits from [UeGeometry](/docs/reference/core/UeGeometry)

## Constructor Parameters

| Parameter    | Type     | Default   | Description                                                                 |
| ------------ | -------- | --------- | --------------------------------------------------------------------------- |
| `radius`     | `number` | `1`       | Radius of the icosahedron                                                   |
| `detail`     | `number` | `0`       | Subdivision level. > 0 transforms the icosahedron into a geodesic sphere.   |
| `data.color` | `Color`  | `c_white` | Optional base color for the vertices (GML format)                           |
| `data.alpha` | `number` | `1`       | Optional base alpha for the vertices                                        |

## Example

```gml
// Creates a simple icosahedron
var geo = new UeIcosahedronGeometry(10, 0);

// Creates a detailed geodesic sphere
var sphereGeo = new UeIcosahedronGeometry(10, 2);
```
