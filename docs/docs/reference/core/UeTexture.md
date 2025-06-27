---
sidebar_position: 3
---

The `UeTexture` class wraps a 2D image or sub-image (frame) into a GPU texture, allowing you to configure sampler settings like filtering, mipmaps, and repeat behavior.

### Constructor
```js
new UeTexture(data = {})
```

### Parameters

| Key               | Type      | Default      | Description                                    |
| ----------------- | --------- | ------------ | ---------------------------------------------- |
| `image`           | `sprite`  | **required** | A sprite resource or image                     |
| `subimg`          | `number`  | `0`          | Sub-image index (frame of the sprite)          |
| `repeat`          | `boolean` | `true`       | Whether the texture repeats outside \[0,1] UVs |
| `filter`          | `boolean` | `true`       | Enables texture smoothing                      |
| `generateMipmaps` | `boolean` | `true`       | Whether to enable mipmaps for minification     |

### Properties

| Property          | Type         | Default   | Description                               |
| -------------     | ------------ | --------- | ------------------------------------      |
| `isTexture`       | `boolean`    | true      | Indicates that this is a texture          |

## 🧩 Methods

```js
setTexture(image, subimg = 0)
```
Changes the source image or sub-image dynamically.

```js
dispose()
```
Cleanup the texture from memory

## 🧠 Notes

- If using a sprite with multiple frames (like a spritesheet), set subimg accordingly.

- Mipmaps improve visual quality when the object is far away or minified.
