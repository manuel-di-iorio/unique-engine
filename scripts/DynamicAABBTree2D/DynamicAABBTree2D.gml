/// @description Dynamic AABB Tree 2D for high-performance spatial partitioning
/// Based on Box2D's b2DynamicTree

function DynamicAABBTree2D(capacity = 1024) constructor {
    self.capacity = capacity;
    self.nodeCount = 0;
    self.root = -1;
    self.freeList = 0;

    // Node data (flat arrays for max performance)
    self.minX = array_create(capacity, 0);
    self.minY = array_create(capacity, 0);
    self.maxX = array_create(capacity, 0);
    self.maxY = array_create(capacity, 0);
    self.parent = array_create(capacity, -1);
    self.left = array_create(capacity, -1);
    self.right = array_create(capacity, -1);
    self.height = array_create(capacity, -1);
    self.userData = array_create(capacity, undefined);
    self.maxDrawIndex = array_create(capacity, -1);

    // Initialize free list
    for (var i = 0; i < capacity - 1; i++) {
        self.left[i] = i + 1;
        self.height[i] = -1;
    }
    self.left[capacity - 1] = -1;
    self.height[capacity - 1] = -1;

    // --- INTERNAL METHODS ---

    static allocateNode = function() {
        if (self.freeList == -1) {
            // Expand arrays
            var oldCapacity = self.capacity;
            self.capacity *= 2;
            
            var newMinX = array_create(self.capacity, 0); array_copy(newMinX, 0, self.minX, 0, oldCapacity); self.minX = newMinX;
            var newMinY = array_create(self.capacity, 0); array_copy(newMinY, 0, self.minY, 0, oldCapacity); self.minY = newMinY;
            var newMaxX = array_create(self.capacity, 0); array_copy(newMaxX, 0, self.maxX, 0, oldCapacity); self.maxX = newMaxX;
            var newMaxY = array_create(self.capacity, 0); array_copy(newMaxY, 0, self.maxY, 0, oldCapacity); self.maxY = newMaxY;
            var newParent = array_create(self.capacity, -1); array_copy(newParent, 0, self.parent, 0, oldCapacity); self.parent = newParent;
            var newLeft = array_create(self.capacity, -1); array_copy(newLeft, 0, self.left, 0, oldCapacity); self.left = newLeft;
            var newRight = array_create(self.capacity, -1); array_copy(newRight, 0, self.right, 0, oldCapacity); self.right = newRight;
            var newHeight = array_create(self.capacity, -1); array_copy(newHeight, 0, self.height, 0, oldCapacity); self.height = newHeight;
            var newUserData = array_create(self.capacity, undefined); array_copy(newUserData, 0, self.userData, 0, oldCapacity); self.userData = newUserData;
            var newMaxDraw = array_create(self.capacity, -1); array_copy(newMaxDraw, 0, self.maxDrawIndex, 0, oldCapacity); self.maxDrawIndex = newMaxDraw;

            for (var i = oldCapacity; i < self.capacity - 1; i++) {
                self.left[i] = i + 1;
                self.height[i] = -1;
            }
            self.left[self.capacity - 1] = -1;
            self.height[self.capacity - 1] = -1;
            self.freeList = oldCapacity;
        }

        var nodeId = self.freeList;
        self.freeList = self.left[nodeId];
        self.parent[nodeId] = -1;
        self.left[nodeId] = -1;
        self.right[nodeId] = -1;
        self.height[nodeId] = 0;
        self.userData[nodeId] = undefined;
        self.maxDrawIndex[nodeId] = -1;
        self.nodeCount++;
        return nodeId;
    };

    static freeNode = function(nodeId) {
        self.left[nodeId] = self.freeList;
        self.height[nodeId] = -1;
        self.userData[nodeId] = undefined; // Clear userData to prevent stale references
        self.freeList = nodeId;
        self.nodeCount--;
    };

    static insertLeaf = function(leafId) {
        if (self.root == -1) {
            self.root = leafId;
            self.parent[self.root] = -1;
            return;
        }

        // Find the best sibling for the new leaf
        var leafMinX = self.minX[leafId];
        var leafMinY = self.minY[leafId];
        var leafMaxX = self.maxX[leafId];
        var leafMaxY = self.maxY[leafId];
        
        var index = self.root;
        while (self.left[index] != -1) {
            var left = self.left[index];
            var right = self.right[index];

            var area = (self.maxX[index] - self.minX[index]) * (self.maxY[index] - self.minY[index]);
            var combinedMinX = min(self.minX[index], leafMinX);
            var combinedMinY = min(self.minY[index], leafMinY);
            var combinedMaxX = max(self.maxX[index], leafMaxX);
            var combinedMaxY = max(self.maxY[index], leafMaxY);
            var combinedArea = (combinedMaxX - combinedMinX) * (combinedMaxY - combinedMinY);

            // Cost of creating a new parent for this node and the new leaf
            var cost = 2 * combinedArea;

            // Minimum cost of pushing the leaf further down the tree
            var inheritanceCost = 2 * (combinedArea - area);

            // Cost of descending into left child
            var costLeft;
            var newMinX = min(self.minX[left], leafMinX);
            var newMinY = min(self.minY[left], leafMinY);
            var newMaxX = max(self.maxX[left], leafMaxX);
            var newMaxY = max(self.maxY[left], leafMaxY);
            if (self.left[left] == -1) {
                costLeft = (newMaxX - newMinX) * (newMaxY - newMinY) + inheritanceCost;
            } else {
                var oldArea = (self.maxX[left] - self.minX[left]) * (self.maxY[left] - self.minY[left]);
                var newArea = (newMaxX - newMinX) * (newMaxY - newMinY);
                costLeft = (newArea - oldArea) + inheritanceCost;
            }

            // Cost of descending into right child
            var costRight;
            newMinX = min(self.minX[right], leafMinX);
            newMinY = min(self.minY[right], leafMinY);
            newMaxX = max(self.maxX[right], leafMaxX);
            newMaxY = max(self.maxY[right], leafMaxY);
            if (self.left[right] == -1) {
                costRight = (newMaxX - newMinX) * (newMaxY - newMinY) + inheritanceCost;
            } else {
                var oldArea = (self.maxX[right] - self.minX[right]) * (self.maxY[right] - self.minY[right]);
                var newArea = (newMaxX - newMinX) * (newMaxY - newMinY);
                costRight = (newArea - oldArea) + inheritanceCost;
            }

            // Descend according to the minimum cost
            if (cost < costLeft && cost < costRight) break;

            if (costLeft < costRight) index = left;
            else index = right;
        }

        var sibling = index;

        // Create a new parent
        var oldParent = self.parent[sibling];
        var newParent = self.allocateNode();
        self.parent[newParent] = oldParent;
        self.userData[newParent] = undefined;
        self.minX[newParent] = min(self.minX[sibling], leafMinX);
        self.minY[newParent] = min(self.minY[sibling], leafMinY);
        self.maxX[newParent] = max(self.maxX[sibling], leafMaxX);
        self.maxY[newParent] = max(self.maxY[sibling], leafMaxY);
        self.height[newParent] = self.height[sibling] + 1;

        if (oldParent != -1) {
            // The sibling was not the root
            if (self.left[oldParent] == sibling) self.left[oldParent] = newParent;
            else self.right[oldParent] = newParent;

            self.left[newParent] = sibling;
            self.right[newParent] = leafId;
            self.parent[sibling] = newParent;
            self.parent[leafId] = newParent;
        } else {
            // The sibling was the root
            self.left[newParent] = sibling;
            self.right[newParent] = leafId;
            self.parent[sibling] = newParent;
            self.parent[leafId] = newParent;
            self.root = newParent;
        }

        // Walk back up the tree fixing heights and AABBs
        index = self.parent[leafId];
        while (index != -1) {
            index = self.balance(index);

            var left = self.left[index];
            var right = self.right[index];

            self.height[index] = 1 + max(self.height[left], self.height[right]);
            self.minX[index] = min(self.minX[left], self.minX[right]);
            self.minY[index] = min(self.minY[left], self.minY[right]);
            self.maxX[index] = max(self.maxX[left], self.maxX[right]);
            self.maxY[index] = max(self.maxY[left], self.maxY[right]);
            
            // Update maxDrawIndex
            var leftDraw = self.maxDrawIndex[left];
            var rightDraw = self.maxDrawIndex[right];
            self.maxDrawIndex[index] = max(leftDraw, rightDraw);

            index = self.parent[index];
        }
    };

    static removeLeaf = function(leafId) {
        if (leafId == self.root) {
            self.root = -1;
            return;
        }

        var parent = self.parent[leafId];
        var grandParent = self.parent[parent];
        var sibling = (self.left[parent] == leafId) ? self.right[parent] : self.left[parent];

        if (grandParent != -1) {
            // Destroy parent and connect sibling to grandParent
            if (self.left[grandParent] == parent) self.left[grandParent] = sibling;
            else self.right[grandParent] = sibling;
            self.parent[sibling] = grandParent;
            self.freeNode(parent);

            // Adjust ancestor bounds
            var index = grandParent;
            while (index != -1) {
                index = self.balance(index);

                var left = self.left[index];
                var right = self.right[index];

                self.minX[index] = min(self.minX[left], self.minX[right]);
                self.minY[index] = min(self.minY[left], self.minY[right]);
                self.maxX[index] = max(self.maxX[left], self.maxX[right]);
                self.maxY[index] = max(self.maxY[left], self.maxY[right]);
                self.height[index] = 1 + max(self.height[left], self.height[right]);
                
                // Update maxDrawIndex
                self.maxDrawIndex[index] = max(self.maxDrawIndex[left], self.maxDrawIndex[right]);

                index = self.parent[index];
            }
        } else {
            self.root = sibling;
            self.parent[sibling] = -1;
            self.freeNode(parent);
        }
    };

    static balance = function(i) {
        if (self.height[i] < 2) return i;

        var a = i;
        var b = self.left[a];
        var c = self.right[a];
        
        // Defensive check: ensure both children are valid
        if (b == -1 || c == -1) return i;
        
        var balance = self.height[c] - self.height[b];

        // Rotate C up
        if (balance > 1) {
            var f = self.left[c];
            var g = self.right[c];

            // Swap A and C
            self.left[c] = a;
            self.parent[c] = self.parent[a];
            self.parent[a] = c;

            // A's old parent should point to C
            if (self.parent[c] != -1) {
                if (self.left[self.parent[c]] == a) self.left[self.parent[c]] = c;
                else self.right[self.parent[c]] = c;
            } else {
                self.root = c;
            }

            // Rotate
            if (self.height[f] > self.height[g]) {
                self.right[c] = f;
                self.right[a] = g;
                self.parent[g] = a;
                self.minX[a] = min(self.minX[b], self.minX[g]);
                self.minY[a] = min(self.minY[b], self.minY[g]);
                self.maxX[a] = max(self.maxX[b], self.maxX[g]);
                self.maxY[a] = max(self.maxY[b], self.maxY[g]);
                self.height[a] = 1 + max(self.height[b], self.height[g]);
                self.maxDrawIndex[a] = max(self.maxDrawIndex[b], self.maxDrawIndex[g]);
                
                self.minX[c] = min(self.minX[a], self.minX[f]);
                self.minY[c] = min(self.minY[a], self.minY[f]);
                self.maxX[c] = max(self.maxX[a], self.maxX[f]);
                self.maxY[c] = max(self.maxY[a], self.maxY[f]);
                self.height[c] = 1 + max(self.height[a], self.height[f]);
                self.maxDrawIndex[c] = max(self.maxDrawIndex[a], self.maxDrawIndex[f]);
            } else {
                self.right[c] = g;
                self.right[a] = f;
                self.parent[f] = a;
                self.minX[a] = min(self.minX[b], self.minX[f]);
                self.minY[a] = min(self.minY[b], self.minY[f]);
                self.maxX[a] = max(self.maxX[b], self.maxX[f]);
                self.maxY[a] = max(self.maxY[b], self.maxY[f]);
                self.height[a] = 1 + max(self.height[b], self.height[f]);
                self.maxDrawIndex[a] = max(self.maxDrawIndex[b], self.maxDrawIndex[f]);
                
                self.minX[c] = min(self.minX[a], self.minX[g]);
                self.minY[c] = min(self.minY[a], self.minY[g]);
                self.maxX[c] = max(self.maxX[a], self.maxX[g]);
                self.maxY[c] = max(self.maxY[a], self.maxY[g]);
                self.height[c] = 1 + max(self.height[a], self.height[g]);
                self.maxDrawIndex[c] = max(self.maxDrawIndex[a], self.maxDrawIndex[g]);
            }

            return c;
        }

        // Rotate B up
        if (balance < -1) {
            var d = self.left[b];
            var e = self.right[b];

            // Swap A and B
            self.left[b] = a;
            self.parent[b] = self.parent[a];
            self.parent[a] = b;

            // A's old parent should point to B
            if (self.parent[b] != -1) {
                if (self.left[self.parent[b]] == a) self.left[self.parent[b]] = b;
                else self.right[self.parent[b]] = b;
            } else {
                self.root = b;
            }

            // Rotate
            if (self.height[d] > self.height[e]) {
                self.right[b] = d;
                self.left[a] = e;
                self.parent[e] = a;
                self.minX[a] = min(self.minX[c], self.minX[e]);
                self.minY[a] = min(self.minY[c], self.minY[e]);
                self.maxX[a] = max(self.maxX[c], self.maxX[e]);
                self.maxY[a] = max(self.maxY[c], self.maxY[e]);
                self.height[a] = 1 + max(self.height[c], self.height[e]);
                self.maxDrawIndex[a] = max(self.maxDrawIndex[c], self.maxDrawIndex[e]);
                
                self.minX[b] = min(self.minX[a], self.minX[d]);
                self.minY[b] = min(self.minY[a], self.minY[d]);
                self.maxX[b] = max(self.maxX[a], self.maxX[d]);
                self.maxY[b] = max(self.maxY[a], self.maxY[d]);
                self.height[b] = 1 + max(self.height[a], self.height[d]);
                self.maxDrawIndex[b] = max(self.maxDrawIndex[a], self.maxDrawIndex[d]);
            } else {
                self.right[b] = e;
                self.left[a] = d;
                self.parent[d] = a;
                self.minX[a] = min(self.minX[c], self.minX[d]);
                self.minY[a] = min(self.minY[c], self.minY[d]);
                self.maxX[a] = max(self.maxX[c], self.maxX[d]);
                self.maxY[a] = max(self.maxY[c], self.maxY[d]);
                self.height[a] = 1 + max(self.height[c], self.height[d]);
                self.maxDrawIndex[a] = max(self.maxDrawIndex[c], self.maxDrawIndex[d]);
                
                self.minX[b] = min(self.minX[a], self.minX[e]);
                self.minY[b] = min(self.minY[a], self.minY[e]);
                self.maxX[b] = max(self.maxX[a], self.maxX[e]);
                self.maxY[b] = max(self.maxY[a], self.maxY[e]);
                self.height[b] = 1 + max(self.height[a], self.height[e]);
                self.maxDrawIndex[b] = max(self.maxDrawIndex[a], self.maxDrawIndex[e]);
            }

            return b;
        }

        return a;
    };

    // --- PUBLIC METHODS ---

    static insert = function(userData, x1, y1, x2, y2) {
        var nodeId = self.allocateNode();
        
        // Fatten the AABB
        var extension = 2.0;
        self.minX[nodeId] = x1 - extension;
        self.minY[nodeId] = y1 - extension;
        self.maxX[nodeId] = x2 + extension;
        self.maxY[nodeId] = y2 + extension;
        self.userData[nodeId] = userData;
        self.height[nodeId] = 0;
        self.maxDrawIndex[nodeId] = userData[$ "__drawIndex"] ?? 0;

        self.insertLeaf(nodeId);
        return nodeId;
    };

    static queryPoint = function(px, py, callback) {
        if (self.root == -1) return;
        
        static stack = array_create(256, -1);
        var stackPtr = 0;
        stack[stackPtr++] = self.root;

        while (stackPtr > 0) {
            var nodeId = stack[--stackPtr];
            if (nodeId == -1) continue;

            if (px >= self.minX[nodeId] && px <= self.maxX[nodeId] &&
                py >= self.minY[nodeId] && py <= self.maxY[nodeId]) {
                
                if (self.left[nodeId] == -1) {
                    // Leaf node
                    if (callback(self.userData[nodeId], nodeId)) return true;
                } else {
                    // Ensure stack has space for 2 more entries
                    if (stackPtr + 2 >= array_length(stack)) {
                        array_resize(stack, array_length(stack) * 2);
                    }
                    stack[stackPtr++] = self.left[nodeId];
                    stack[stackPtr++] = self.right[nodeId];
                }
            }
        }
        return false;
    };
    
    // Optimized: get the topmost element at a point
    static getTopmostAtPoint = function(px, py) {
        if (self.root == -1) return undefined;
        
        var bestElem = undefined;
        var bestDrawIndex = -1;
        
        static stack = array_create(256, -1);
        var stackPtr = 0;
        stack[stackPtr++] = self.root;

        while (stackPtr > 0) {
            var nodeId = stack[--stackPtr];
            
            // Optimization: skip branches where maxDrawIndex is lower than what we already found
            if (self.maxDrawIndex[nodeId] <= bestDrawIndex) continue;

            // Check point in AABB
            if (px >= self.minX[nodeId] && px <= self.maxX[nodeId] &&
                py >= self.minY[nodeId] && py <= self.maxY[nodeId]) {
                
                if (self.left[nodeId] == -1) {
                    // Leaf node
                    var drawIdx = self.maxDrawIndex[nodeId];
                    if (drawIdx > bestDrawIndex) {
                        bestDrawIndex = drawIdx;
                        bestElem = self.userData[nodeId];
                    }
                } else {
                    // Ensure stack has space for 2 more entries
                    if (stackPtr + 2 >= array_length(stack)) {
                        array_resize(stack, array_length(stack) * 2);
                    }
                    
                    // Push children. To optimize, push the one with lower maxDrawIndex first,
                    // so we process the one with higher maxDrawIndex later (LIFO) and potentially prune more.
                    var left = self.left[nodeId];
                    var right = self.right[nodeId];
                    
                    if (self.maxDrawIndex[left] < self.maxDrawIndex[right]) {
                        stack[stackPtr++] = left;
                        stack[stackPtr++] = right;
                    } else {
                        stack[stackPtr++] = right;
                        stack[stackPtr++] = left;
                    }
                }
            }
        }
        return bestElem;
    };

    static clear = function() {
        self.nodeCount = 0;
        self.root = -1;
        self.freeList = 0;
        for (var i = 0; i < self.capacity - 1; i++) {
            self.left[i] = i + 1;
            self.height[i] = -1;
            self.userData[i] = undefined;
        }
        self.left[self.capacity - 1] = -1;
        self.height[self.capacity - 1] = -1;
        self.userData[self.capacity - 1] = undefined;
    };
    
    // Move a proxy to a new AABB (incremental update)
    // Note: This preserves the existing maxDrawIndex. Use updateDrawIndex() after move() 
    //       if the draw order needs to be updated.
    static move = function(proxyId, minX, minY, maxX, maxY) {
        if (proxyId < 0 || proxyId >= self.capacity) return false;
        if (self.height[proxyId] == -1) return false; // Not a valid proxy
        if (self.left[proxyId] != -1) return false; // Not a leaf node
        
        // Check if the new AABB is significantly different
        var extension = 2.0;
        var fatMinX = minX - extension;
        var fatMinY = minY - extension;
        var fatMaxX = maxX + extension;
        var fatMaxY = maxY + extension;
        
        // If new AABB is still contained in the old fat AABB, no need to reinsert
        if (fatMinX >= self.minX[proxyId] && fatMinY >= self.minY[proxyId] &&
            fatMaxX <= self.maxX[proxyId] && fatMaxY <= self.maxY[proxyId]) {
            return true; // Movement is small enough, tree structure is still valid
        }
        
        // Save userData and drawIndex before removal
        var userData = self.userData[proxyId];
        var drawIndex = self.maxDrawIndex[proxyId];
        
        // Remove and reinsert
        self.removeLeaf(proxyId);
        self.minX[proxyId] = fatMinX;
        self.minY[proxyId] = fatMinY;
        self.maxX[proxyId] = fatMaxX;
        self.maxY[proxyId] = fatMaxY;
        // Restore userData and drawIndex
        self.userData[proxyId] = userData;
        self.maxDrawIndex[proxyId] = drawIndex;
        self.insertLeaf(proxyId);
        
        return true;
    };
    
    // Remove a proxy from the tree
    static remove = function(proxyId) {
        if (proxyId < 0 || proxyId >= self.capacity) return false;
        if (self.height[proxyId] == -1) return false; // Not a valid proxy
        
        self.removeLeaf(proxyId);
        self.freeNode(proxyId);
        return true;
    };
    
    // Update the draw index of a proxy and propagate maxDrawIndex up the tree
    static updateDrawIndex = function(proxyId, drawIndex) {
        if (proxyId < 0 || proxyId >= self.capacity) return false;
        if (self.height[proxyId] == -1) return false; // Not a valid proxy
        
        self.maxDrawIndex[proxyId] = drawIndex;
        
        // Propagate maxDrawIndex up to ancestors
        var index = self.parent[proxyId];
        while (index != -1) {
            var left = self.left[index];
            var right = self.right[index];
            var newMax = max(self.maxDrawIndex[left], self.maxDrawIndex[right]);
            
            // Early exit if maxDrawIndex didn't change
            if (self.maxDrawIndex[index] == newMax) break;
            
            self.maxDrawIndex[index] = newMax;
            index = self.parent[index];
        }
        
        return true;
    };
}
