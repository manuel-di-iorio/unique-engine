---
sidebar_position: 1
---

The `UeTransformControls` class allows objects to be transformed (moved, rotated, scaled) using a visual gizmo.  
It provides an interactive way for users to manipulate 3D objects in the scene.

### Constructor
```js
new UeTransformControls(camera, data = {})
```

### Data parameters

| Key          | Type                   | Default            | Description                                      |
| ------------ | ---------------------- | ------------------ | ------------------------------------------------ |
| `camera`     | `UeCamera`             | **required**       | The camera used for raycasting and rendering     |
| `object`     | `UeObject3D`           | `undefined`        | The object to control                            |
| `mode`       | `string`               | `"view"`           | Initial mode: `"view"`, `"move"`, `"rotate"`, `"scale"` |
| `space`      | `string`               | `"world"`          | Transform space: `"world"` or `"local"`          |
| `size`       | `number`               | `1.3`              | Visual size of the gizmo                         |
| `snap`       | `number` or `undefined`| `undefined`        | General snap increment (legacy)                  |
| `moveSnap`   | `number` or `undefined`| `undefined`        | Snap increment for movement                      |
| `rotateSnap` | `number` or `undefined`| `undefined`        | Snap increment for rotation (in degrees)         |
| `scaleSnap`  | `number` or `undefined`| `undefined`        | Snap increment for scaling                       |

### Properties

| Property      | Type         | Description                                      |
| ------------- | ------------ | ------------------------------------------------ |
| `camera`      | `UeCamera`   | The camera used for interaction                  |
| `object`      | `UeObject3D` | The currently attached object                    |
| `mode`        | `string`     | Current mode: `"move"`, `"rotate"`, `"scale"`    |
| `space`       | `string`     | Transformation space: `"world"` or `"local"`     |
| `size`        | `number`     | Size multiplier for the gizmo                    |
| `dragging`    | `boolean`    | Whether the user is currently dragging the gizmo |
| `axis`        | `string`     | The currently selected axis (e.g., "X", "XY")    |

## Methods

```js
attach(object)
```
Attaches the controls to a 3D object.

```js
detach()
```
Detaches the controls from the current object.

```js
setMode(mode)
```
Sets the interaction mode.
- `mode`: `"move"`, `"rotate"`, `"scale"`, or `"view"` (hidden).

```js
setSpace(space)
```
Sets the coordinate space for transformations.
- `space`: `"world"` or `"local"`.

```js
setSize(size)
```
Sets the visual size of the gizmo.

```js
update()
```
Updates the gizmo logic. Must be called every frame.
Automatically handles mouse interaction and object transformation.

```js
getHelper()
```
Returns the `UeMesh` root of the gizmo, which should be added to the scene to be visible.

## Modes

### Move
Allows translation along the X, Y, Z axes or the XY, XZ, YZ planes.
In "local" space, axes align with the object's rotation.

### Rotate
Allows rotation around the X, Y, Z axes.
Provides a screen-space rotation circle (outer ring).

### Scale
Allows scaling of the object.
- **Axes (Red, Green, Blue)**: Scale along specific local axes.
- **Planes**: Scale along two axes simultaneously.
- **Center Cube**: Uniform scaling on all axes.
  - Uniform scaling uses a visual "drag" distance logic for intuitive control.

## Events

The controls emit events via `dispatchEvent` (inherited from `UeControls` -> `UeEventDispatcher`).

- `change`: Fired when the object is transformed.
- `mouseDown`: Fired when drag starts.
- `mouseUp`: Fired when drag ends.

## Usage Example

```js
// Create controls
var transformControls = new UeTransformControls(camera);
scene.add(transformControls.getHelper());

// Attach to an object
transformControls.attach(myObject);

// Set mode
transformControls.setMode("scale");

// In Step Event
transformControls.update();
```
