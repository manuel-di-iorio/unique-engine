---
sidebar_position: 7
---

Represents a mathematical plane in 3D space defined by a normal vector and a distance from the origin. Useful for geometric tests, projections, culling, and physics.

---

## Constructor

```js
new UePlane(normal = new UeVector3(0, 1, 0), d = 0)
```

### Parameters

| Name     | Type        | Default                  | Description                                      |
| -------- | ----------- | ------------------------ | ------------------------------------------------ |
| `normal` | `UeVector3` | `new UeVector3(0, 1, 0)` | The normal vector of the plane                   |
| `d`      | `number`    | `0`                      | The signed distance from the origin along normal |

## Methods

| Method                         | Returns     | Description                                                              |
| ------------------------------ | ----------- | ------------------------------------------------------------------------ |
| `setFromNormalAndPoint(n, pt)` | `self`      | Sets the plane from a normal and a point on the plane                    |
| `setFromPoints(p1, p2, p3)`    | `self`      | Defines the plane using 3 non-collinear points                           |
| `distanceToPoint(pt)`          | `number`    | Returns the signed distance from a point to the plane                    |
| `projectPoint(pt)`             | `UeVector3` | Projects a point onto the plane                                          |
| `isPointOnPlane(pt, epsilon)`  | `boolean`   | Returns `true` if the point lies on the plane (within epsilon tolerance) |
| `clone()`                      | `UePlane`   | Returns a deep copy of the plane                                         |
| `copy(plane)`                  | `self`      | Copies the values from another `UePlane` instance                        |
| `flip()`                       | `self`      | Inverts the plane (reverses normal and distance)                         |

## Example

```js
var plane = new UePlane();
plane.setFromPoints(
  new UeVector3(0, 0, 0),
  new UeVector3(1, 0, 0),
  new UeVector3(0, 1, 0)
);

var point = new UeVector3(0, 0, 5);
var projected = plane.projectPoint(point);
```
