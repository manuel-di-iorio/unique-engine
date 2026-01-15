function UeLod(data = {}): UeObject3D(data) constructor {
    isLOD = true;
    type = "LOD";
    
    autoUpdate = data[$ "autoUpdate"] ?? true;
    levels = [];
    _currentLevel = 0;

    static _refreshThresholds = function() {
        var len = array_length(levels);
        if (len == 0) return;

        for (var i = 0; i < len; i++) {
            var l = levels[i];
            
            // enterSq: threshold to move from i to i-1 (upgrade)
            // It depends on the distance of level i
            l.enterSq = (i > 0) ? sqr(levels[i].distance * (1 - levels[i].hysteresis)) : -1;
            
            // exitSq: threshold to move from i to i+1 (downgrade)
            // It depends on the distance of level i+1
            l.exitSq = (i < len - 1) ? sqr(levels[i + 1].distance * (1 + levels[i + 1].hysteresis)) : infinity;
            
            // Hide by default, we'll show the correct one in update or init
            l.object.visible = false;
        }
        
        // Initial state: Level 0 visible
        _currentLevel = 0;
        if (len > 0) levels[0].object.visible = true;
    }

    static addLevel = function(object, distance = 0, hysteresis = 0) {
        distance = abs(distance);
        
        var l = {
            object: object,
            distance: distance,
            hysteresis: hysteresis,
            enterSq: 0,
            exitSq: 0
        };
        
        var index = 0;
        for (var i = 0, len = array_length(levels); i < len; i++) {
            if (distance < levels[i].distance) {
                break;
            }
            index++;
        }
        
        array_insert(levels, index, l);
        self.add(object);
        
        _refreshThresholds();
        return self;
    }

    static getCurrentLevel = function() {
        return _currentLevel;
    }

    static getObjectForDistance = function(distance) {
        if (array_length(levels) == 0) return undefined;
        
        for (var i = 1, len = array_length(levels); i < len; i++) {
            if (distance < levels[i].distance) {
                return levels[i - 1].object;
            }
        }
        
        return levels[array_length(levels) - 1].object;
    }

    static raycast = function(raycaster, intersects) {
        var len = array_length(levels);
        if (len > 0) {
            // Use current level if possible for speed, or compute from distance
            var object = levels[_currentLevel].object;
            object.raycast(raycaster, intersects);
        }
    }

    static removeLevel = function(distance) {
        for (var i = 0, len = array_length(levels); i < len; i++) {
            if (levels[i].distance == distance) {
                self.remove(levels[i].object);
                array_delete(levels, i, 1);
                _refreshThresholds();
                return true;
            }
        }
        return false;
    }

    static update = function(camera) {
        var len = array_length(levels);
        if (len == 0) return;

        var distSq = self[$ "__distanceToCameraSq"];
        
        // Fallback if not updated by renderer
        if (distSq == undefined) {
            var v1 = global.UE_VEC3_TEMP0;
            var v2 = global.UE_VEC3_TEMP1;
            
            vec3_set_from_matrix_position(v1, camera.matrixWorld);
            vec3_set_from_matrix_position(v2, self.matrixWorld);
            
            distSq = vec3_distance_to_squared(v1, v2);
        }
        
        var i = _currentLevel;
        var cur = levels[i];

        // Downgrade (less detail)
        if (i < len - 1 && distSq > cur.exitSq) {
            cur.object.visible = false;
            i++;
            levels[i].object.visible = true;
            _currentLevel = i;
            return;
        }

        // Upgrade (more detail)
        if (i > 0 && distSq < cur.enterSq) {
            cur.object.visible = false;
            i--;
            levels[i].object.visible = true;
            _currentLevel = i;
            return;
        }
        
        // Ensure visibility if it was lost (e.g. manual change)
        cur.object.visible = true;
    }
}
