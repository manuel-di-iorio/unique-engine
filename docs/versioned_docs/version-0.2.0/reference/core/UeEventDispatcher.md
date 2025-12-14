---
sidebar_position: 12
---

# UeEventDispatcher

Base class that provides a lightweight event system for all engine objects. It is used as the parent class for `UeTransform`, which means every object that inherits from `UeTransform` (including `UeObject3D`, `UeMesh`, cameras, etc.) automatically gains event capabilities.

## Constructor
```js
new UeEventDispatcher()
```
Creates an empty dispatcher. Internally it stores listeners in a private `_listeners` struct.

## Methods (inherited via `UeEventDispatcher`)
- **on(type, listener)** – Registers `listener` for the given event `type`.
- **off(type, listener)** – Unregisters a previously added listener.
- **once(type, listener)** – Registers a listener that will be invoked only the first time the event fires, then automatically removed.
- **dispatch(event)** – Fires an event struct. The struct must contain a `type` field (string). The dispatcher sets `event.target` to the object during propagation.

## Event struct
```js
var event = {
    type: "added",   // name of the event
    data: any,        // optional payload
    target: undefined // will be set by dispatcher
};
```

## Usage example
```js
var obj = new UeObject3D();
obj.on("added", function(e) {
    show_debug_message("Object added to parent!");
});

var parent = new UeObject3D();
parent.add(obj); // triggers "added" on obj and "childAdded" on parent
```
