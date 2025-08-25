---
sidebar_position: 7
---

Represents a mathematical plane in 3D space defined by a normal vector and a distance from the origin. Useful for geometric tests, projections, culling, and physics.

---

## Constructor

```js
new UePlane(normal = new UeVector3(0, 0, -1), d = 0)
```

### Properties

| Name       | Type        | Default                   | Description                                       |
| --------   | ----------- | ------------------------  | ------------------------------------------------  |
| `normal`   | `UeVector3` | `new UeVector3(0, 0, -1)` | The normal vector of the plane                    |
| `constant` | `number`    | `0`                       | The signed distance from the origin along normal  |
| `isPlane`  | `boolean`   | `true`                    | Indicates that this is a plane                    |

## Methods

| Method                                | Returns      | Description                                                              |
| ------------------------------        | -----------  | ------------------------------------------------------------------------ |
| `setFromNormalAndPoint(n, pt)`        | `self`       | Sets the plane from a normal and a point on the plane                    |
| `setFromPoints(p1, p2, p3)`           | `self`       | Defines the plane using 3 non-collinear points                           |
| `distanceToPoint(pt)`                 | `number`     | Returns the signed distance from a point to the plane                    |
| `projectPoint(pt)`                    | `UeVector3`  | Projects a point onto the plane                                          |
| `isPointOnPlane(pt, epsilon)`         | `boolean`    | Returns `true` if the point lies on the plane (within epsilon tolerance) |
| `clone()`                             | `UePlane`    | Returns a deep copy of the plane                                         |
| `copy(plane)`                         | `self`       | Copies the values from another `UePlane` instance                        |
| `flip()`                              | `self`       | Inverts the plane (reverses normal and distance)                         |
| `applyMatrix4(matrix, normalMat)`     | `self`       | Applies a transform matrix to the plane (requires affine matrix)    |
| `coplanarPoint()`                     | `UeVector3`  | Returns a point coplanar to the plane                               |
| `distanceToSphere(sphere)`            | `number`     | Returns signed distance from the sphere to the plane                |
| `equals(plane)`                       | `boolean`    | Returns `true` if two planes are equal (same normal and constant)   |
| `intersectsBox(box)`                  | `boolean`    | Returns `true` if the plane intersects the AABB box                 |
| `intersectsSphere(sphere)`            | `boolean`    | Returns `true` if the plane intersects the sphere                   |
| `negate()`                            | `self`       | Inverts the normal and constant                                     |
| `normalize()`                         | `self`       | Normalizes the normal and adjusts the constant accordingly          |
| `set(normal, constant)`               | `self`       | Sets the plane’s normal and constant                                |
| `setComponents(x, y, z, w)`           | `self`       | Sets the plane using individual components                          |
| `setFromNormalAndCoplanarPoint(n,pt)` | `self`       | Alias of `setFromNormalAndPoint`                                    |
| `setFromCoplanarPoints(a, b, c)`      | `self`       | Alias of `setFromPoints`                                            |
| `translate(offset)`                   | `self`       | Translates the plane by the given offset vector                     |
| `intersectLine(line)`                 | `UeVector3`  | Returns the intersection point between a line and the plane, if any |

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
