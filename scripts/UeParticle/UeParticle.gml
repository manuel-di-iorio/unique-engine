function UeParticle() constructor {
  
    // State
    alive = false;
    age   = 0;
    life  = 0;

    // Transform
    posX = [];
    posY = [];
    posZ = [];
    velocity = vec3_create(0,0,0);

    // Rendering
    size   = 1;
    rotation = 0;
    color  = vec4_create(1,1,1,1);

    // Extra
    sortKey = 0; // For depth sorting
}