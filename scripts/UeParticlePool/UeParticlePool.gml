/** 
* @description Ultra-performance SoA (Structure of Arrays) pool for GPU-simulated particles. 
* Stores birth data and manages a zero-allocation free list with O(1) operations.
*/
function UeParticlePool(maxCount) constructor {
  gml_pragma("forceinline");
  self.maxCount = maxCount;
  self.aliveCount = 0;

  // --- SoA Arrays (Birth Data) ---
  self.spawnX = array_create(maxCount, 0);
  self.spawnY = array_create(maxCount, 0);
  self.spawnZ = array_create(maxCount, 0);
  
  self.initVelX = array_create(maxCount, 0);
  self.initVelY = array_create(maxCount, 0);
  self.initVelZ = array_create(maxCount, 0);
  
  self.gravityX = array_create(maxCount, 0);
  self.gravityY = array_create(maxCount, 0);
  self.gravityZ = array_create(maxCount, 0);
  
  self.life = array_create(maxCount, 0);
  self.maxLife = array_create(maxCount, 0);
  
  self.sizeStart = array_create(maxCount, 0);
  self.sizeEnd = array_create(maxCount, 0);
  
  self.colorStart = array_create(maxCount, 0); // 32bit BGRA
  self.colorEnd = array_create(maxCount, 0);   // 32bit BGRA
  
  self.rotStart = array_create(maxCount, 0);
  self.rotSpeed = array_create(maxCount, 0);
  
  self.seed = array_create(maxCount, 0); 

  // --- Management Lists ---
  self.activeIndices = array_create(maxCount, 0);
  self.freeIndices = array_create(maxCount, 0);
  self.freeCount = maxCount;

  // Initialize free list stack
  for (var i = 0; i < maxCount; i++) self.freeIndices[i] = i;

  /** 
  * @description Pops an index from the free list and moves it to the active list.
  * @returns {real} The physical index in the SoA arrays, or -1 if full.
  */ 
  static allocate = function () {
    gml_pragma("forceinline");
    if (self.freeCount == 0) return -1;
    var idx = self.freeIndices[--self.freeCount];
    self.activeIndices[self.aliveCount++] = idx;
    return idx;
  }

  /**
  * @description Releases an active particle back to the free list.
  * @param {real} activeIndex The position in the activeIndices array (not the physical index).
  */
  static free = function (activeIndex) {
    gml_pragma("forceinline");
    var realIdx = self.activeIndices[activeIndex];
    self.freeIndices[self.freeCount++] = realIdx;
    self.aliveCount--;
    self.activeIndices[activeIndex] = self.activeIndices[self.aliveCount];
  }
  
  /**
  * @description Efficiently decrements particle life and kills expired particles using swap-remove.
  * @param {real} dt Delta time in seconds.
  */
  static updateLife = function(dt) {
    gml_pragma("forceinline");
    var count = self.aliveCount;
    if (count <= 0) return;
    
    var active = self.activeIndices;
    var lifeArr = self.life;
    var i = 0;
    while (i < count) {
        var idx = active[i];
        lifeArr[idx] -= dt;
        if (lifeArr[idx] <= 0) {
            self.freeIndices[self.freeCount++] = idx;
            count--;
            active[i] = active[count];
        } else {
            i++;
        }
    }
    self.aliveCount = count;
  }
}
