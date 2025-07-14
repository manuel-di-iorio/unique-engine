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

| Method                      | Returns      | Description                                                                |
| --------------------------- | ------------ | -------------------------------------------------------------------------- |
| `setFromPoints(from, to)`   | `self`       | Sets the ray using two points: `from` and `to`                             |
| `getPoint(t)`               | `UeVector3`  | Returns the point at distance `t` along the ray                            |
| `intersectPlane(plane)`     | `UeVector3?` | Intersects the ray with a plane, returns intersection point or `undefined` |
| `distanceToPoint(pt)`       | `number`     | Computes shortest distance from a point to the ray                         |
| `isPointClose(pt, maxDist)` | `boolean`    | Returns `true` if point is within `maxDist` units of the ray               |
| `clone()`                   | `UeRay`      | Returns a deep copy of the ray                                             |
| `copy(ray)`                 | `self`       | Copies the origin and direction from another ray                           |


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
