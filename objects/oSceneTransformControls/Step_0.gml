switch (tool) {
    case "view": 
        control.updateGizmo();
        orbit.update(); 
    break;
    case "move":
    case "rotate":
    case "scale":
        control.update();
    break;
}
