switch (control.mode) {
    case "move":
    case "rotate":
    case "scale":
        control.update();
    break;
}

if (!control.dragging) {
    control.updateGizmo();
    orbit.update();
}