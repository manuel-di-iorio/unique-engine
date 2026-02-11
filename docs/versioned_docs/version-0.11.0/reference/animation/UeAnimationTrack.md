---
sidebar_position: 4
---

# UeAnimationTrack

Manages keyframes for a single node identified by name.

## Constructor
```js
new UeAnimationTrack(nodeName)
```

### Parameters
- `nodeName`: The name of the object to animate.

## Properties
- `nodeName`: Target name.
- `positionKeys`: Array of `{ time, value: vec3 }`.
- `rotationKeys`: Array of `{ time, value: quat }`.
- `scaleKeys`: Array of `{ time, value: vec3 }`.

## Methods
### `interpolate(time)`
Returns a `{ position, rotation, scale }` object with interpolated values for the specified time.
- `time`: Time in ticks.
