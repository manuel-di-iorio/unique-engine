---
sidebar_position: 3
---

The `UeTexture` class wraps a 2D image or sub-image (frame) into a GPU texture, allowing you to configure sampler settings like filtering, mipmaps, and repeat behavior.

### Constructor
```js
new UeTexture(data = {})
```

### Data parameters

| Key               | Type      | Default      | Description                                    |
| ----------------- | --------- | ------------ | ---------------------------------------------- |
| `image`           | `sprite`  | **required** | A sprite resource or image                     |
| `subimg`          | `number`  | `0`          | Sub-image index (frame of the sprite)          |
| `repeat`          | `boolean` | `true`       | Whether the texture repeats                    |
| `filter`          | `boolean` | `true`       | Enables texture smoothing                      |
| `generateMipmaps` | `boolean` | `true`       | Whether to enable mipmaps for minification     |

### Properties

| Property          | Type         | Default     | Description                                    |
| -------------     | ------------ | ---------   | ------------------------------------           |
| `isTexture`       | `boolean`    | true        | Indicates that this is a texture               |
| `type`            | `string`     | `"Texture"` | Object type                                    |
| `name`            | `string`     | ""          | Object name                                    |
| `uuid`            | `string`     |             | Resource UUID                                  |

## 🧩 Methods

```js
setTexture(image, subimg = 0)
```
Changes the source image or sub-image dynamically.

```js
dispose()
```
Cleanup the texture from memory

```js
toJSON()
```

Returns an object representing this entity's properties. Not all props may be included.

## 🧠 Notes

- If using a sprite with multiple frames (like a spritesheet), set subimg accordingly.

- Mipmaps improve visual quality when the object is far away or minified.
