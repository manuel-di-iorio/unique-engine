---
sidebar_position: 2
---

A 2D vector class with common vector operations. Useful for positions, directions, and geometry in 2D space.

---

### Constructor

```js
new UeVector2(x = 0, y = 0)
```

### Data parameters

| Name | Type     | Default | Description  |
| ---- | -------- | ------- | ------------ |
| `x`  | `number` | `0`     | X coordinate |
| `y`  | `number` | `0`     | Y coordinate |

## Methods

| Method            | Returns     | Description                                        |
| ----------------- | ----------- | -------------------------------------------------- |
| `set(x, y)`       | `self`      | Sets the X and Y components                        |
| `clone()`         | `UeVector2` | Returns a copy of this vector                      |
| `copy(vec)`       | `self`      | Copies values from another vector                  |
| `add(vec)`        | `self`      | Adds another vector                                |
| `sub(vec)`        | `self`      | Subtracts another vector                           |
| `multiply(vec)`   | `self`      | Multiplies each component by another vector        |
| `scale(s)`        | `self`      | Scales both components by scalar `s`               |
| `dot(vec)`        | `number`    | Dot product with another vector                    |
| `length()`        | `number`    | Magnitude (Euclidean norm)                         |
| `normalize()`     | `self`      | Converts to a unit vector                          |
| `equals(vec)`     | `boolean`   | Checks if two vectors are identical                |
| `lerp(vec, t)`    | `self`      | Linear interpolation toward `vec` by factor `t`    |
| `angleTo(vec)`    | `number`    | Returns angle in degrees between the vectors       |
| `distanceTo(vec)` | `number`    | Euclidean distance to another vector               |
| `perp()`          | `UeVector2` | Returns a perpendicular vector (`-y, x`)           |
| `rotate(angle)`   | `self`      | Rotates the vector counterclockwise by angle       |
