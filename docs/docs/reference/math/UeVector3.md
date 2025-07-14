---
sidebar_position: 3
---

A 3D vector class that supports common vector math operations. Used for positions, directions, and geometric calculations in 3D space.

---

## Constructor

```js
new UeVector3(x = 0, y = 0, z = 0)
```

### Data parameters

| Name | Type     | Default | Description |
| ---- | -------- | ------- | ----------- |
| `x`  | `number` | `0`     | X component |
| `y`  | `number` | `0`     | Y component |
| `z`  | `number` | `0`     | Z component |

## Methods

| Method                        | Returns     | Description                                          |
| ----------------------------- | ----------- | ---------------------------------------------------- |
| `set(x, y, z)`                | `this`      | Sets the vector components                           |
| `clone()`                     | `UeVector3` | Returns a deep copy                                  |
| `copy(vec)`                   | `this`      | Copies values from another vector                    |
| `add(vec)`                    | `this`      | Adds another vector                                  |
| `sub(vec)`                    | `this`      | Subtracts another vector                             |
| `multiply(vec)`               | `this`      | Multiplies by another vector component-wise          |
| `scale(scalar)`               | `this`      | Scales this vector by a scalar                       |
| `dot(vec)`                    | `number`    | Dot product with another vector                      |
| `cross(vec)`                  | `UeVector3` | Cross product with another vector                    |
| `length()`                    | `number`    | Euclidean length of the vector                       |
| `normalize()`                 | `this`      | Normalizes the vector                                |
| `equals(vec)`                 | `boolean`   | Checks if the vectors are equal in all components    |
| `lerp(vec, t)`                | `this`      | Linearly interpolates toward another vector          |
| `angleTo(vec)`                | `number`    | Angle between vectors (radians)                      |
| `distanceTo(vec)`             | `number`    | Euclidean distance to another vector                 |
| `distanceToSquared(vec)`      | `number`    | Squared distance (faster)                            |
| `addScalar(s)`                | `this`      | Adds a scalar to all components                      |
| `addScaledVector(vec, scale)` | `this`      | Adds another vector scaled by a factor               |
| `addVectors(a, b)`            | `this`      | Sets this as a + b                                   |
| `clamp(minVec, maxVec)`       | `this`      | Clamps components between two vectors                |
| `clampScalar(min, max)`       | `this`      | Clamps components between scalar limits              |
| `clampLength(min, max)`       | `this`      | Clamps the vector's length                           |
| `divide(vec)`                 | `this`      | Divides by another vector component-wise             |
| `divideScalar(scalar)`        | `this`      | Divides all components by a scalar                   |
| `floor()`                     | `this`      | Applies `floor()` to all components                  |
| `ceil()`                      | `this`      | Applies `ceil()` to all components                   |
| `round()`                     | `this`      | Rounds all components                                |
| `roundToZero()`               | `this`      | Rounds each component toward zero                    |
| `lengthSq()`                  | `number`    | Squared length of the vector                         |
| `manhattanLength()`           | `number`    | Manhattan length (sum of absolute components)        |
| `manhattanDistanceTo(vec)`    | `number`    | Manhattan distance to another vector                 |
| `multiplyScalar(s)`           | `this`      | Alias for `scale(s)`                                 |
| `multiplyVectors(a, b)`       | `this`      | Multiplies vectors component-wise                    |
| `negate()`                    | `this`      | Negates all components                               |
| `setScalar(s)`                | `this`      | Sets all components to the same scalar value         |
| `setX(x)`                     | `this`      | Sets only the X component                            |
| `setY(y)`                     | `this`      | Sets only the Y component                            |
| `setZ(z)`                     | `this`      | Sets only the Z component                            |
| `subScalar(s)`                | `this`      | Subtracts a scalar from all components               |
| `subVectors(a, b)`            | `this`      | Sets this as a - b                                   |
| `applyMatrix3(mat)`           | `this`      | Transforms vector with a 3x3 matrix                  |
| `applyMatrix4(mat)`           | `this`      | Transforms vector with a 4x4 matrix                  |
| `applyNormalMatrix(mat)`      | `this`      | Applies normal matrix (3x3) and normalizes result    |
| `transformDirection(mat)`     | `this`      | Transforms only direction and normalizes             |
| `project(camera)`             | `this`      | Projects to camera NDC space (-1 to 1)               |
| `unproject(camera)`           | `this`      | Unprojects from NDC to world space                   |
| `projectOnPlane(normal)`      | `this`      | Projects the vector onto a plane                     |
| `projectOnVector(vec)`        | `this`      | Projects the vector onto another vector              |
| `reflect(normal)`             | `this`      | Reflects the vector along a normal                   |
| `setLength(len)`              | `this`      | Sets the vector's length                             |
| `fromArray(arr, offset = 0)`  | `this`      | Sets components from an array                        |
| `getComponent(index)`         | `number`    | Gets a component by index (0: x, 1: y, 2: z)         |
| `toArray(arr?, offset = 0)`   | `Array`     | Converts vector to array                             |
| `random()`                    | `this`      | Fills the vector with random values in range \[0, 1) |
| `randomDirection()`           | `this`      | Sets the vector to a random unit direction           |
