---
sidebar_position: 10
---

A 3D axis-aligned bounding box (AABB) class that defines a cuboid using minimum and maximum Vector3 corners. Useful for spatial partitioning, collision detection, and geometric operations in 3D space.

---

## Constructor

```js
new UeBox3(min = new UeVector3(infinity, infinity, infinity), max = new UeVector3(-infinity, -infinity, -infinity))
```

### Data parameters

| Name  | Type        | Default                             | Description               |
| ----- | ----------- | ----------------------------------- | ------------------------- |
| `min` | `UeVector3` | `(infinity, infinity, infinity)`    | Minimum corner of the box |
| `max` | `UeVector3` | `(-infinity, -infinity, -infinity)` | Maximum corner of the box |


## Methods

| Method                               | Returns     | Description                                                          |
| ------------------------------------ | ----------- | -------------------------------------------------------------------- |
| `clone()`                            | `UeBox3`    | Returns a copy of this box                                           |
| `set(min, max)`                      | `self`      | Sets the min and max corners of the box                              |
| `setFromArray(arr)`                  | `self`      | Sets the box bounds from a flat array of 3D points                   |
| `setFromCenterAndSize(center, size)` | `self`      | Builds the box using a center point and size                         |
| `setFromPoints(points)`              | `self`      | Expands the box to fit a set of 3D points                            |
| `setFromObject(object, precise)`     | `self`      | Sets the box from an object's geometry (optionally precise)          |
| `copy(box)`                          | `self`      | Copies the bounds from another box                                   |
| `makeEmpty()`                        | `self`      | Empties the box so it contains no points                             |
| `isEmpty()`                          | `boolean`   | Returns `true` if the box is empty (max < min)                       |
| `expandByPoint(point)`               | `self`      | Expands the box to include a given point                             |
| `expandByScalar(scalar)`             | `self`      | Expands the box in all directions by a scalar                        |
| `expandByVector(vec)`                | `self`      | Expands the box in all directions by a vector                        |
| `expandByObject(object, precise)`    | `self`      | Expands the box to include an object's bounding box                  |
| `containsPoint(point)`               | `boolean`   | Returns `true` if the point is inside the box                        |
| `containsBox(box)`                   | `boolean`   | Returns `true` if the given box is fully inside this box             |
| `intersect(box)`                     | `self`      | Updates this box to be the intersection of itself and another        |
| `intersectsBox(box)`                 | `boolean`   | Returns `true` if the two boxes intersect                            |
| `intersectsPlane(plane)`             | `boolean`   | Returns `true` if the box intersects a given plane                   |
| `getCenter(target)`                 | `UeVector3` | Returns the center point of the box                                  |
| `getSize(target)`                   | `UeVector3` | Returns the size (width, height, depth) of the box                   |
| `getParameter(point, target)`       | `UeVector3` | Returns normalized coordinates of a point relative to the box (0..1) |
| `applyMatrix4(matrix)`               | `self`      | Applies a 4x4 transformation matrix to the box                       |
| `translate(offset)`                  | `self`      | Moves the box by an offset                                           |
| `equals(box)`                        | `boolean`   | Checks whether this box is equal to another (min and max match)      |
| `clampPoint(point, target)`         | `UeVector3` | Clamps a point to stay within the box limits                         |
| `distanceToPoint(point)`             | `number`    | Returns distance from point to the box (0 if point is inside)        |
| `getBoundingSphere(target)`          | `Object`    | Calculates the bounding sphere that encloses the box                 |
| `union(box)`                         | `self`      | Merges this box with another, expanding the bounds                   |
