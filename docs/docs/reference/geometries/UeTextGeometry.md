---
sidebar_position: 15
---

Represents a 3D text geometry created from a GameMaker font asset.  
It uses `font_get_info` to generate a mesh composed of quads for each character, supporting alignment, kerning, and line spacing.

```js
new UeTextGeometry(text, font, data = {})
```

> Inherits from [UeGeometry](/docs/reference/core/UeGeometry)

## Constructor parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `text` | `string` | `""` | The text content to render. |
| `font` | `Font` | `-1` | The GameMaker font asset. |
| `data.halign` | `constant` | `fa_left` | Horizontal alignment (`fa_left`, `fa_center`, `fa_right`). |
| `data.valign` | `constant` | `fa_top` | Vertical alignment (`fa_top`, `fa_middle`, `fa_bottom`). |
| `data.size` | `number` | `1.0` | Scaling factor for the text. |
| `data.lineHeight` | `number` | `1.0` | Vertical multiplier for line spacing. |
| `data.spacing` | `number` | `0` | Extra horizontal spacing between characters. |
| `data.color` | `Color` | `c_white` | Base color for the vertices. |
| `data.alpha` | `number` | `1.0` | Base alpha for the vertices. |

## Methods

### `setText(newText)`
Updates the text content and rebuilds the geometry.

| Parameter | Type | Description |
| --- | --- | --- |
| `newText` | `string` | The new string to display. |
