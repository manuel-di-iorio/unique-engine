controls.update();

skeletonHelper.update();

// Update the animation time using delta_time (converted to seconds)
var deltaTime = delta_time / 1000000;
currentTime += deltaTime;

// Evaluate the animation and apply transforms to the model hierarchy
anim0.evaluate(currentTime, modelRoot);
