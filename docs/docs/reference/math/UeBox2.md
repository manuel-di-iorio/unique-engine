---
sidebar_position: 9
---

A 2D axis-aligned bounding box (AABB) class that defines a rectangle using minimum and maximum Vector2 corners. Useful for spatial partitioning, collision checks, and geometric operations in 2D space.

---

## Constructor

```js
new UeBox2(min = new UeVector2(infinity, infinity), max = new UeVector2(-infinity, -infinity))
```

### Data parameters

| Name  | Type        | Default                  | Description               |
| ----- | ----------- | ------------------------ | ------------------------- |
| `min` | `UeVector2` | `(infinity, infinity)`   | Minimum corner of the box |
| `max` | `UeVector2` | `(-infinity, -infinity)` | Maximum corner of the box |


## Methods

| Method                               | Returns     | Description                                                          |
| ------------------------------------ | ----------- | -------------------------------------------------------------------- |
| `clone()`                            | `UeBox2`    | Returns a copy of this box                                           |
| `set(min, max)`                      | `this`      | Sets the min and max corners of the box                              |
| `makeEmpty()`                        | `this`      | Empties the box so it contains no points                             |
| `isEmpty()`                          | `boolean`   | Returns `true` if the box is empty (max < min)                       |
| `setFromPoints(points[])`            | `this`      | Expands the box to fit a set of 2D points                            |
| `setFromCenterAndSize(center, size)` | `this`      | Builds the box using a center point and size                         |
| `copy(box)`                          | `this`      | Copies the bounds from another box                                   |
| `expandByPoint(point)`               | `this`      | Expands the box to include a given point                             |
| `expandByScalar(scalar)`             | `this`      | Expands the box in all directions by a scalar                        |
| `expandByVector(vec)`                | `this`      | Expands the box in all directions by a vector                        |
| `containsPoint(point)`               | `boolean`   | Returns `true` if the point is inside the box                        |
| `containsBox(box)`                   | `boolean`   | Returns `true` if the given box is fully inside this box             |
| `intersect(box)`                     | `this`      | Updates this box to be the intersection of itself and another        |
| `intersectsBox(box)`                 | `boolean`   | Returns `true` if the two boxes intersect                            |
| `union(box)`                         | `this`      | Merges this box with another, expanding the bounds                   |
| `getCenter(target?)`                 | `UeVector2` | Returns the center point of the box                                  |
| `getSize(target?)`                   | `UeVector2` | Returns the size (width, height) of the box                          |
| `getParameter(point, target?)`       | `UeVector2` | Returns normalized coordinates of a point relative to the box (0..1) |
| `clampPoint(point, target?)`         | `UeVector2` | Clamps a point to stay within the box limits                         |
| `distanceToPoint(point)`             | `number`    | Returns distance from point to the box (0 if point is inside)        |
| `translate(offset)`                  | `this`      | Moves the box by an offset                                           |
| `equals(box)`                        | `boolean`   | Checks whether this box is equal to another (min and max match)      |
