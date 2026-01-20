---
sidebar_position: 1
---

# UeAnimation

Class representing a set of animation tracks for an object hierarchy.

## Constructor
```js
new UeAnimation(name, duration, ticksPerSecond = 24)
```

### Parameters
- `name`: Identifier string for the animation.
- `duration`: Total duration in ticks.
- `ticksPerSecond`: Playback speed (default 24).

## Properties
- `name`: Name of the animation.
- `duration`: Duration in ticks.
- `ticksPerSecond`: Ticks per second.
- `tracks`: Array of `UeAnimationTrack`.

## Methods
### `addTrack(track)`
Adds a `UeAnimationTrack` to this animation.
- `track`: The `UeAnimationTrack` instance to add.

### `evaluate(time, root)`
Calculates the animation state at the specified time and applies it to the hierarchy starting from `root`.
- `time`: Time in seconds.
- `root`: The `UeObject3D` root object of the hierarchy.
