---
sidebar_position: 4
---

# UeSpriteMaterial

A simplified material designed for 2D-like rendering of flat meshes or billboards. It is optimized for performance by skipping lighting calculations and handling transparency out of the box.

Inherits from [UeMaterial](/docs/reference/core/UeMaterial).

---

### Constructor

```js
new UeSpriteMaterial(data = {})
```

### Data Parameters

| Name           | Type      | Default            | Description                                  |
| -------------- | --------- | ------------------ | -------------------------------------------- |
| `data.map`     | `Texture` | `undefined`        | The albedo texture for the sprite            |
| `data.color`   | `color`   | `c_white`          | Tint color for the sprite                    |
| `data.transparent` | `bool` | `true`             | Whether the material supports transparency   |
| `data.side`    | `const`   | `cull_noculling`   | Side culling mode                            |

---

### Properties

| Property      | Type      | Default            | Description                                  |
| ------------- | --------- | ------------------ | -------------------------------------------- |
| `shader`      | `shader`  | `sh_ue_sprite`     | The shader used for rendering                |
| `lights`      | `int`     | `0`                | Number of lights (always 0 for this material)|
| `transparent` | `bool`    | `true`             | Transparency flag                            |
| `color`       | `array`   | `[1, 1, 1]`        | Normalized RGB tint color                    |

---

## 🎨 Usage

`UeSpriteMaterial` is specifically used with [UeSprite](/docs/reference/objects/UeSprite). It automatically manages the `sh_ue_sprite` shader which supports specialized features like camera-facing orientation and axis locking.

```js
var material = new UeSpriteMaterial({
    map: new UeTexture(spr_particle),
    color: c_orange,
    transparent: true
});
```
