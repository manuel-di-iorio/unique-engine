---
sidebar_position: 11
---

A bounding sphere defined by a center point and a radius. Useful for spatial queries, collision detection, and bounding volume hierarchies in 3D.

---

## Constructor

```js
new UeSphere(center = new UeVector3(0, 0, 0), radius = -1)
```

### Data parameters

| Name     | Type        | Default     | Description                           |
| -------- | ----------- | ----------- | ------------------------------------- |
| `center` | `UeVector3` | `(0, 0, 0)` | Center point of the sphere            |
| `radius` | `number`    | `-1`        | Radius of the sphere; < 0 means empty |


## Methods

| Method                                   | Returns     | Description                                                       |
| ---------------------------------------- | ----------- | ----------------------------------------------------------------- |
| `set(center, radius)`                    | `self`      | Sets the center and radius of the sphere                          |
| `copy(sphere)`                           | `self`      | Copies values from another sphere                                 |
| `clone()`                                | `UeSphere`  | Returns a new copy of this sphere                                 |
| `isEmpty()`                              | `boolean`   | Returns `true` if radius is less than 0 (sphere is empty)         |
| `makeEmpty()`                            | `self`      | Makes the sphere empty                                            |
| `containsPoint(point)`                   | `boolean`   | Returns `true` if the point is inside or on the surface           |
| `distanceToPoint(point)`                 | `number`    | Returns distance from the surface to a point (negative if inside) |
| `clampPoint(point, target)`             | `UeVector3` | Clamps a point inside the sphere boundary                         |
| `applyMatrix4(matrix)`                   | `self`      | Applies a 4x4 transformation matrix to the sphere                 |
| `expandByPoint(point)`                   | `self`      | Expands the sphere to include the given point                     |
| `setFromPoints(points, optionalCenter)` | `self`      | Sets the sphere from an array of points, optionally with a center |
| `translate(offset)`                      | `self`      | Moves the sphere by an offset vector                              |
| `equals(sphere)`                         | `boolean`   | Checks if this sphere equals another (same center and radius)     |
| `getBoundingBox(target)`                | `UeBox3`    | Returns the minimal bounding box enclosing this sphere            |
| `intersectsBox(box)`                     | `boolean`   | Returns `true` if the sphere intersects a given box               |
| `intersectsPlane(plane)`                 | `boolean`   | Returns `true` if the sphere intersects a given plane             |
| `intersectsSphere(sphere)`               | `boolean`   | Returns `true` if this sphere intersects another sphere           |
| `union(sphere)`                          | `self`      | Expands this sphere to include another sphere                     |
