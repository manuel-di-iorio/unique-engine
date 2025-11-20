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

| Method                              | Returns     | Description                                          |
| -----------------------------       | ----------- | ---------------------------------------------------- |
| `set(x, y, z)`                      | `self`      | Sets the vector components                           |
| `clone()`                           | `UeVector3` | Returns a deep copy                                  |
| `copy(vec)`                         | `self`      | Copies values from another vector                    |
| `add(vec)`                          | `self`      | Adds another vector                                  |
| `sub(vec)`                          | `self`      | Subtracts another vector                             |
| `multiply(vec)`                     | `self`      | Multiplies by another vector component-wise          |
| `scale(scalar)`                     | `self`      | Scales this vector by a scalar                       |
| `dot(vec)`                          | `number`    | Dot product with another vector                      |
| `cross(vec)`                        | `UeVector3` | Cross product with another vector                    |
| `crossVectors(a, b)`                | `self`      | Sets this vector to cross product of a and b         |
| `length()`                          | `number`    | Euclidean length of the vector                       |
| `normalize()`                       | `self`      | Normalizes the vector                                |
| `equals(vec)`                       | `boolean`   | Checks if the vectors are equal in all components    |
| `lerp(vec, t)`                      | `self`      | Linearly interpolates toward another vector          |
| `angleTo(vec)`                      | `number`    | Angle between vectors (degrees)                      |
| `distanceTo(vec)`                   | `number`    | Euclidean distance to another vector                 |
| `distanceToSquared(vec)`            | `number`    | Squared distance (faster)                            |
| `addScalar(s)`                      | `self`      | Adds a scalar to all components                      |
| `addScaledVector(vec, scale)`       | `self`      | Adds another vector scaled by a factor               |
| `addVectors(a, b)`                  | `self`      | Sets this as a + b                                   |
| `clamp(minVec, maxVec)`             | `self`      | Clamps components between two vectors                |
| `clampScalar(min, max)`             | `self`      | Clamps components between scalar limits              |
| `clampLength(min, max)`             | `self`      | Clamps the vector's length                           |
| `divide(vec)`                       | `self`      | Divides by another vector component-wise             |
| `divideScalar(scalar)`              | `self`      | Divides all components by a scalar                   |
| `floor()`                           | `self`      | Applies `floor()` to all components                  |
| `ceil()`                            | `self`      | Applies `ceil()` to all components                   |
| `round()`                           | `self`      | Rounds all components                                |
| `roundToZero()`                     | `self`      | Rounds each component toward zero                    |
| `lengthSq()`                        | `number`    | Squared length of the vector                         |
| `manhattanLength()`                 | `number`    | Manhattan length (sum of absolute components)        |
| `manhattanDistanceTo(vec)`          | `number`    | Manhattan distance to another vector                 |
| `multiplyScalar(s)`                 | `self`      | Alias for `scale(s)`                                 |
| `multiplyVectors(a, b)`             | `self`      | Multiplies vectors component-wise                    |
| `negate()`                          | `self`      | Negates all components                               |
| `setScalar(s)`                      | `self`      | Sets all components to the same scalar value         |
| `setX(x)`                           | `self`      | Sets only the X component                            |
| `setY(y)`                           | `self`      | Sets only the Y component                            |
| `setZ(z)`                           | `self`      | Sets only the Z component                            |
| `subScalar(s)`                      | `self`      | Subtracts a scalar from all components               |
| `subVectors(a, b)`                  | `self`      | Sets this as a - b                                   |
| `applyMatrix3(mat)`                 | `self`      | Transforms vector with a 3x3 matrix                  |
| `applyMatrix4(mat)`                 | `self`      | Transforms vector with a 4x4 matrix                  |
| `applyNormalMatrix(mat)`            | `self`      | Applies normal matrix (3x3) and normalizes result    |
| `transformDirection(mat)`           | `self`      | Transforms only direction and normalizes             |
| `project(camera)`                   | `self`      | Projects to camera NDC space (-1 to 1)               |
| `unproject(camera)`                 | `self`      | Unprojects from NDC to world space                   |
| `projectOnPlane(normal)`            | `self`      | Projects the vector onto a plane                     |
| `projectOnVector(vec)`              | `self`      | Projects the vector onto another vector              |
| `reflect(normal)`                   | `self`      | Reflects the vector along a normal                   |
| `setLength(len)`                    | `self`      | Sets the vector's length                             |
| `fromArray(arr, offset = 0)`        | `self`      | Sets components from an array                        |
| `getComponent(index)`               | `number`    | Gets a component by index (0: x, 1: y, 2: z)         |
| `toArray(arr, offset = 0)`         | `Array`     | Converts vector to array                             |
| `random()`                          | `self`      | Fills the vector with random values in range \[0, 1) |
| `randomDirection()`                 | `self`      | Sets the vector to a random unit direction           |
| `setFromMatrixColumn(matrix, i)`    | `self`      | Sets components from the column at index `i` of a 4×4 matrix.                          |
| `setFromMatrix3Column(matrix, i)`   | `self`      | Sets components from the column at index `i` of a 3×3 matrix.                          |
| `setFromMatrixPosition(matrix)`     | `self`      | Sets components from the position (translation) column of a 4×4 matrix.                |
| `setFromMatrixScale(matrix)`        | `self`      | Extracts scale components from the 3×3 part of a matrix and sets them.                 |
| `setComponent(index, value)`        | `self`      | Sets a single component by index (`0`: x, `1`: y, `2`: z).                             |
| `minVec(vec)`                          | `self`      | Sets each component to the minimum of itself and the corresponding component in `vec`. |
| `maxVec(vec)`                          | `self`      | Sets each component to the maximum of itself and the corresponding component in `vec`. |
| `setFromSphericalCoords(r, φ, θ)`   | `self`      | Sets vector components from spherical coordinates (`radius`, `phi`, `theta`).          |
| `setFromCylindricalCoords(r, θ, y)` | `self`      | Sets vector components from cylindrical coordinates (`radius`, `theta`, `y`).          |
| `applyQuaternion(q)`                | `self`      | Rotates this vector by a quaternion.                                                   |
| `applyAxisAngle(axis, angle)`       | `self`      | Rotates this vector around an arbitrary axis using Rodrigues' formula.                 |
