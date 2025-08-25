---
sidebar_position: 8
---

Represents a ray in 3D space defined by an origin and a normalized direction vector. Commonly used for intersection tests, picking, and visibility checks.

---

## Constructor

```js
new UeRay(origin = new UeVector3(), direction = new UeVector3(0, 0, -1))
```

### Data parameters

| Name        | Type        | Default                   | Description                                |
| ----------- | ----------- | ------------------------- | ------------------------------------------ |
| `origin`    | `UeVector3` | `new UeVector3()`         | The origin point of the ray                |
| `direction` | `UeVector3` | `new UeVector3(0, 0, -1)` | The direction of the ray (auto-normalized) |

## Methods

| Method                                                                      | Returns                  | Description                                                                                   |
| --------------------------------------------------------------------------- | ------------------------ | --------------------------------------------------------------------------------------------- |
| `setFromPoints(from, to)`                                                   | `self`                   | Sets origin and direction based on two points                                                 |
| `getPoint(t)`                                                               | `UeVector3`              | Returns point at distance `t` along the ray                                                   |
| `intersectPlane(plane)`                                                     | `UeVector3 \| undefined` | Returns intersection point with a plane or `undefined` if no intersection                     |
| `distanceToPoint(point)`                                                    | `number`                 | Returns shortest distance from ray to a point                                                 |
| `isPointClose(point, maxDist)`                                              | `boolean`                | Checks if a point is within `maxDist` from the ray                                            |
| `clone()`                                                                   | `UeRay`                  | Returns a copy of this ray                                                                    |
| `copy(ray)`                                                                 | `self`                   | Copies origin and direction from another ray                                                  |
| `applyMatrix4(matrix4)`                                                     | `self`                   | Applies a 4x4 transformation matrix to origin and direction                                   |
| `at(t, target)`                                                             | `UeVector3`              | Writes point at distance `t` along the ray into `target` and returns it                       |
| `closestPointToPoint(point, target)`                                        | `UeVector3`              | Returns closest point on the ray to a given point, stored in `target`                         |
| `distanceSqToPoint(point)`                                                  | `number`                 | Returns squared distance from ray to a point                                                  |
| `distanceSqToSegment(v0, v1, optionalPointOnRay, optionalPointOnSegment)` | `number`                 | Returns squared distance between ray and segment `v0`-`v1`; optionally outputs closest points |
| `distanceToPlane(plane)`                                                    | `number \| undefined`    | Returns distance from origin to intersection with plane along the ray, or `undefined` if none |
| `distanceToPoint(point)`                                                    | `number`                 | Returns distance from ray to point                                                            |
| `equals(ray)`                                                               | `boolean`                | Returns true if origin and direction equal another ray                                        |
| `intersectBox(box, target)`                                                | `UeVector3 \| undefined` | Returns intersection point with axis-aligned bounding box or `undefined` if none              |
| `intersectPlane(plane, target)`                                            | `UeVector3 \| null`      | Returns intersection point with plane or `null` if none                                       |
| `intersectSphere(sphere, target)`                                          | `UeVector3 \| null`      | Returns intersection point with sphere or `null` if none                                      |
| `intersectTriangle(a, b, c, backfaceCulling, target)`                      | `UeVector3 \| null`      | Returns intersection point with triangle or `null` if none                                    |
| `intersectsBox(box)`                                                        | `boolean`                | Returns true if ray intersects an axis-aligned bounding box                                   |
| `intersectsPlane(plane)`                                                    | `boolean`                | Returns true if ray intersects a plane                                                        |
| `intersectsSphere(sphere)`                                                  | `boolean`                | Returns true if ray intersects a sphere                                                       |
| `lookAt(v)`                                                                 | `self`                   | Sets the ray direction to look at vector `v` (world space)                                    |
| `recast(t)`                                                                 | `self`                   | Moves the origin along the direction by distance `t`                                          |
| `set(origin, direction)`                                                    | `self`                   | Sets origin and normalized direction                                                          |



## Example

```js
var ray = new UeRay();
var plane = new UePlane().setFromNormalAndPoint(
  new UeVector3(0, 1, 0),
  new UeVector3(0, 5, 0)
);

var hit = ray.intersectPlane(plane);
if (hit != undefined) {
  show_debug_message("Ray hit plane at: " + string(hit));
}
```
