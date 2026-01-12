/**
 * @description Data-oriented container for particles.
 * Stores particle properties in separate arrays (SoA) for better performance in GML.
 */
function UeParticlePool(maxCount) constructor {
    self.maxCount = maxCount;
    self.aliveCount = 0;

    // Position
    self.posX = array_create(maxCount, 0);
    self.posY = array_create(maxCount, 0);
    self.posZ = array_create(maxCount, 0);

    // Velocity
    self.velX = array_create(maxCount, 0);
    self.velY = array_create(maxCount, 0);
    self.velZ = array_create(maxCount, 0);

    // Color & Alpha
    self.colorR = array_create(maxCount, 1);
    self.colorG = array_create(maxCount, 1);
    self.colorB = array_create(maxCount, 1);
    self.alpha  = array_create(maxCount, 1);

    // Transform
    self.size     = array_create(maxCount, 1);
    self.rotation = array_create(maxCount, 0);

    // Life
    self.age  = array_create(maxCount, 0);
    self.life = array_create(maxCount, 0);

    // Sorting/Rendering
    self.sortKey = array_create(maxCount, 0);
    self.indices = array_create(maxCount, 0);
    for (var i = 0; i < maxCount; i++) self.indices[i] = i;
    self.indicesScratch = array_create(maxCount, 0);

    /**
     * Resets a particle at the given index.
     */
    function reset(index) {
        gml_pragma("forceinline");
        self.posX[index] = 0;
        self.posY[index] = 0;
        self.posZ[index] = 0;
        self.velX[index] = 0;
        self.velY[index] = 0;
        self.velZ[index] = 0;
        self.colorR[index] = 1;
        self.colorG[index] = 1;
        self.colorB[index] = 1;
        self.alpha[index] = 1;
        self.size[index] = 1;
        self.rotation[index] = 0;
        self.age[index] = 0;
        self.life[index] = 0;
    }

    /**
     * Swaps two particles in the container.
     * Useful for killing particles by swapping with the last alive one.
     */
    function swap(i, j) {
        gml_pragma("forceinline");
        var tmp;

        tmp = self.posX[i]; self.posX[i] = self.posX[j]; self.posX[j] = tmp;
        tmp = self.posY[i]; self.posY[i] = self.posY[j]; self.posY[j] = tmp;
        tmp = self.posZ[i]; self.posZ[i] = self.posZ[j]; self.posZ[j] = tmp;

        tmp = self.velX[i]; self.velX[i] = self.velX[j]; self.velX[j] = tmp;
        tmp = self.velY[i]; self.velY[i] = self.velY[j]; self.velY[j] = tmp;
        tmp = self.velZ[i]; self.velZ[i] = self.velZ[j]; self.velZ[j] = tmp;

        tmp = self.colorR[i]; self.colorR[i] = self.colorR[j]; self.colorR[j] = tmp;
        tmp = self.colorG[i]; self.colorG[i] = self.colorG[j]; self.colorG[j] = tmp;
        tmp = self.colorB[i]; self.colorB[i] = self.colorB[j]; self.colorB[j] = tmp;
        tmp = self.alpha[i];  self.alpha[i]  = self.alpha[j];  self.alpha[j]  = tmp;

        tmp = self.size[i];     self.size[i]     = self.size[j];     self.size[j]     = tmp;
        tmp = self.rotation[i]; self.rotation[i] = self.rotation[j]; self.rotation[j] = tmp;

        tmp = self.age[i];  self.age[i]  = self.age[j];  self.age[j]  = tmp;
        tmp = self.life[i]; self.life[i] = self.life[j]; self.life[j] = tmp;
        
        tmp = self.sortKey[i]; self.sortKey[i] = self.sortKey[j]; self.sortKey[j] = tmp;
    }
}
