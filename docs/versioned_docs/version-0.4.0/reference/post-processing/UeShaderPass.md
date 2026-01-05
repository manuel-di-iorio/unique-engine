# UeShaderPass

`UeShaderPass` is a generic pass that applies a custom shader to the entire screen. It's useful for effects like grayscale, vignette, color correction, etc.

## Constructor

```js
new UeShaderPass(material, textureUniformName?)
```

- **material**: `UeMaterial` - The material containing the shader to apply.
- **textureUniformName** (optional): string - The uniform name for the input texture. Default is `"map"`.

## Usage

1. Create a `UeMaterial` with your custom shader.
2. Initialize `UeShaderPass` with this material.
3. Add it to the composer.

The input texture (previous pass output) will be automatically bound to the material's texture slot specified by `textureUniformName`.

## Example

```js
var myMaterial = new UeMaterial({ shader: sh_my_custom_effect });
var effectPass = new UeShaderPass(myMaterial);
composer.addPass(effectPass);
```
