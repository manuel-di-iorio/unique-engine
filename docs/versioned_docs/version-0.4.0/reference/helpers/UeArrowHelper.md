---
sidebar_position: 2
---

Visual helper that represents a 3D arrow using a shaft (line) and a head (cone). 

This is useful for debugging vectors like directions, normals, or rays.

---

## Constructor

```js
new UeArrowHelper(dir, origin, length, color, headLength, headWidth)
```

> Inherits from [UeLineSegments](/docs/reference/objects/UeLineSegments)

## Parameters

| Parameter    | Type      | Default            | Description                                                  |
| ------------ | --------- | ------------------ | ------------------------------------------------------------ |
| `dir`        | `Vector3` |                    | Direction vector (must be normalized or will be normalized). |
| `origin`     | `Vector3` |                    | Starting point of the arrow.                                 |
| `length`     | `number`  | `1`                | Total length of the arrow.                                   |
| `color`      | `Color`   | `c_yellow`         | Color of both the shaft and the head of the arrow.           |
| `headLength` | `number`  | `0.1 * length`     | Length of the arrowhead (cone).                              |
| `headWidth`  | `number`  | `0.2 * headLength` | Width of the arrowhead (cone).                               |

## Properties

| Property | Type     | Description                                         |
| -------- | -------- | --------------------------------------------------- |
| `line`   | `UeLine` | The line segment that forms the shaft of the arrow. |
| `cone`   | `UeMesh` | The cone mesh that forms the arrowhead.             |

## Methods

| Method                                       | Returns | Description                                                                        |
| -------------------------------------------- | ------- | ---------------------------------------------------------------------------------- |
| `setDirection(dir)`                          | `self`  | Updates the arrow's orientation to point in the new direction. Will be normalized  |
| `setLength(length, headLength, headWidth)` | `self`  | Changes the overall size of the arrow.                                             |
| `setColor(color)`                            | `self`  | Changes the color of both the line and cone parts.                                 |


## Usage

```js
var dir = new UeVector3(0, 1, 0);
var origin = new UeVector3(10, 0, 0);
var arrow = new UeArrowHelper(dir, origin, 100, c_lime);
scene.add(arrow);
```
