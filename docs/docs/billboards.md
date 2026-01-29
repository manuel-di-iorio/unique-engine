---
sidebar_position: 6
---

# Billboards (UeSprite)

Billboards are 2D objects that always face the camera (or have specific facing behaviors). They are commonly used for particles, distant trees, foliage, lights flares, or UI elements in the 3D world. 

In Unique Engine, a billboard is represented by the `UeSprite` class, which is a specialized type of `UeMesh` that uses a plane geometry and a dedicated material (`UeSpriteMaterial`).

---

## 🌲 Creating a Billboard

To create a billboard, you typically need a texture (the image to display) and a material.

### Step 1: Create the Texture
First, load or reference the sprite you want to use.

```js
// Create the texture from a GameMaker sprite
var texture = new UeTexture(spr_tex_palm_tree);
```

### Step 2: Create the Material
Use `UeSpriteMaterial` for billboards. This material is optimized for 2D rendering and handles transparency automatically.

```js
// Create the material
var material = new UeSpriteMaterial({ 
    map: texture,
    transparent: true, // Typically true for sprites
    color: c_white     // Optional tint color
});
```

### Step 3: Create the Sprite
Finally, create the `UeSprite` instance and add it to the scene.

```js
// Create the billboard mesh and add it to the scene
var sprite = new UeSprite(material, { 
    x: 0, 
    y: 0, 
    z: 10,
    scale: vec3_create(2, 2, 1) // Scale the sprite if needed
});

scene.add(sprite);
```

---

## 🖼️ How it works

The `UeSprite` automatically uses a `UePlaneGeometry` internally. The magic happens in the rendering pipeline where `UeSprite` objects are treated to maintain their orientation relative to the camera.

When using `UeSpriteMaterial`, the engine uses `sh_ue_sprite`, a shader specifically designed to render these quads without lighting calculations (by default), making them very efficient.

---

## ⚙️ Properties and Customization

Since `UeSprite` inherits from `UeMesh`, you can manipulate it just like any other 3D object:

- **Position**: `sprite.position` or `sprite.setPosition(x, y, z)`
- **Scale**: `sprite.scale` or `sprite.setScale(x, y, z)`
- **Rotation**: Typically billboards handle rotation automatically, but you can apply Z-rotation for 2D-like spinning.

### Common Use Cases

1. **Foliage**: Trees and grass that are far away.
2. **Particles**: Smoke, fire, or magic effects.
3. **Icons/UI**: Floating markers above characters.
4. **Projectiles**: Bullets or energy balls in a retro-style shooter.
