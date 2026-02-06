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

| Key           | Type       | Default     | Description                                     |
| ------------- | ---------- | ----------- | ----------------------------------------------- |
| `view`        | `number`   | `0`         | The GameMaker view index to use for projections |
| `onDragStart` | `function` | `undefined` | Callback fired when dragging begins             |
| `onDrag`      | `function` | `undefined` | Callback fired every frame while dragging       |
| `onDragEnd`   | `function` | `undefined` | Callback fired when dragging stops              |
| `snapEnabled` | `boolean`  | `false`     | Whether grid snapping is enabled by default     |
| `snapSize`    | `number`   | `10`        | The default snapping increment                  |

### Properties

| Property      | Type         | Description                                      |
| ------------- | ------------ | ------------------------------------------------ |
| `camera`      | `UeCamera`   | The camera used for interaction                  |
| `object`      | `UeObject3D` | The currently attached object                    |
| `mode`        | `string`     | Current mode: `"move"`, `"rotate"`, `"scale"`    |
| `space`       | `string`     | Transformation space: `"world"` or `"local"`     |
| `size`        | `number`     | Size multiplier for the gizmo                    |
| `enabled`     | `boolean`    | Whether the gizmo is active and visible          |
| `view`        | `number`     | The GameMaker view index being used              |
| `dragging`    | `boolean`    | Whether the user is currently dragging the gizmo |
| `hoveredAxis` | `enum`       | The axis currently under the mouse (`UE_GIZMO_AXIS`) |
| `selectedAxis`| `enum`       | The axis currently being dragged (`UE_GIZMO_AXIS`) |
| `lineWidth`   | `number`     | Thickness of gizmo lines in pixels (default: 3)    |
| `hitThreshold`| `number`     | Pixel distance for mouse picking (default: 10)     |
| `axisLength`  | `number`     | Length of the axes in world units (default: 1.5)   |
| `snapEnabled` | `boolean`    | Whether grid snapping is enabled                   |
| `snapSize`    | `number`     | Current grid snapping increment                    |

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
- `mode`: `"move"`, `"rotate"`, or `"scale"`.

```js
updateGizmo()
```
Updates the gizmo's internal state (matrices, position, scale). Useful for updating the gizmo's orientation without processing mouse interactions.

```js
update()
```
The main update loop. Handles interaction logic (picking and dragging). Must be called in the Step event.

```js
render()
```
Draws the gizmo. Must be called in the **Draw GUI** event.

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

## Snapping

`UeTransformControls` supports grid snapping for the **Move** mode (translation). When enabled, coordinates will be rounded to the nearest multiple of `snapSize`.

- **snapEnabled**: Toggle snapping on/off.
- **snapSize**: Set the increment for snapping (e.g., 10, 50, 100 world units).

In the editor, this can be toggled using the **Grid Snap** icon in the scene tools bar.

## Callbacks

The controls use callbacks provided in the `data` struct during initialization.

- `onDragStart`: Fired when the user starts dragging a gizmo axis.
- `onDrag`: Fired every frame while the gizmo is being dragged.
- `onDragEnd`: Fired when the user releases the mouse button.

## Usage Example

```js
// Create controls
var transformControls = new UeTransformControls(camera, {
    view: 0,
    onDrag: function() {
        show_debug_message("Object is being transformed!");
    }
});

// Attach to an object
transformControls.attach(myObject);

// Set mode
transformControls.setMode("move");

// In Step Event
transformControls.update();

// In Draw GUI Event
transformControls.render();
```
