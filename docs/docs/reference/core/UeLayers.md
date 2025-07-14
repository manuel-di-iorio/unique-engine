---
sidebar_position: 11
---

The **UeLayers** class manages membership of an object in up to 32 layers (0 to 31), represented internally as a bitmask. By default, an object is assigned to layer 0.

Layers are used to control visibility: an object is visible to a camera only if the object's layers intersect with the camera's layers.

All classes inheriting from `Object3D` have a `layers` property which is an instance of this class.

## Constructor

### `new UeLayers()`

Creates a new Layers object with membership initially set to layer 0.

## Properties

| Property | Type    | Description                                      |
| -------- | ------- | ------------------------------------------------|
| `mask`   | Integer | Bitmask representing active layers (32 bits).  |

## Methods

| Method             | Parameters             | Returns  | Description                                                                                       |
| ---------------    | ---------------------- | -------- | ------------------------------------------------------------------------------------------------- |
| `disable(layer)`   | `layer: Integer`       | `this`   | Removes membership from the specified layer (0 to 31).                                            |
| `enable(layer)`    | `layer: Integer`       | `this`   | Adds membership to the specified layer (0 to 31).                                                 |
| `set(layer)`       | `layer: Integer`       | `this`   | Sets membership to only the specified layer, removing all others.                                 |
| `test(layers)`     | `layers: UeLayers`     | `Boolean`| Returns true if this Layers object shares at least one common layer with the given Layers object. |
| `isEnabled(layer)` | `layer: Integer`       | `Boolean`| Returns true if the specified layer is enabled.                                                   |
| `toggle(layer)`    | `layer: Integer`       | `this`   | Toggles membership of the specified layer.                                                        |
| `enableAll()`      |                        | `this`   | Enables membership in all 32 layers.                                                              |
| `disableAll()`     |                        | `this`   | Disables membership from all layers.                                                              |

## Example

```js
const layers = new UeLayers();
layers.enable(1);
layers.disable(0);
if (layers.isEnabled(1)) {
    console.log("Layer 1 is enabled.");
}
