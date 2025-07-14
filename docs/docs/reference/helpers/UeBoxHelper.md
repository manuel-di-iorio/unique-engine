---
sidebar_position: 1
---

A helper class that creates and updates a wireframe bounding box around a 3D object.
Useful for visual debugging or highlighting the bounding volume of an object.

---

## Constructor

```js
new UeBoxHelper(object, color = #FFFF00, data = {})
```

> Inherits from [UeLineSegments](/docs/reference/objects/UeLineSegments)

### Data parameters

| Name   | Type     | Default   | Description                                  |
| ------ | -------- | --------- | -------------------------------------------- |
| object | `Object` | undefined | The 3D object to create the bounding box for |
| color  | `Color`  | `#FFFF00` | Color of the bounding box lines              |
| data   | `Object` | `{}`      | Additional data to pass to the base class    |

### Properties

| Property   | Type                  | Description                        |
| ---------- | --------------------- | ---------------------------------- |
| `object`   | `Object`              | The target 3D object               |
| `color`    | `Color`               | Color used for the bounding box    |
| `material` | `UeLineBasicMaterial` | Material used for the bounding box |


## Methods

```js
updateBox()
```
- Updates the bounding box geometry based on the current state of the target object.

- Computes the bounding box from the object’s geometry.

- Rebuilds the line vertices representing the box edges.

- Applies the object's transform (position, rotation, scale) to the bounding box helper.

```js
setFromObject(object)
```
Updates the helper to track a new object.

| Parameter | Type     | Description             |
| --------- | -------- | ----------------------- |
| object    | `Object` | The new object to track |


## Usage Notes

- The bounding box updates automatically on creation.

- Call setFromObject() to change the target object and update the box.

- The helper copies the transform of the tracked object to maintain correct positioning, rotation and scaling.
