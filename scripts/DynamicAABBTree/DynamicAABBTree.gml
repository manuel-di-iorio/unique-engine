/// @desc Dynamic AABB Tree for 3D spatial partitioning
/// Highly efficient for dynamic objects.

/// @func dynamic_aabb_tree_create(fattening = 0.1)
/// @desc Constructs a new Dynamic AABB Tree.
/// @param {Real} [fattening] Extra margin for leaf AABBs
/// @returns {Struct} New Dynamic AABB Tree
function dynamic_aabb_tree_create(fattening = 0.1) {
    return {
        root: undefined,
        fattening: fattening
    };
}

/// @func dynamic_aabb_tree_insert(tree, object, aabb)
/// @desc Inserts an object into the tree.
/// @param {Struct} tree The tree
/// @param {Any} object The object to insert
/// @param {Array} aabb The Box3 of the object
/// @returns {Struct} The new leaf node
function dynamic_aabb_tree_insert(tree, object, aabb) {
    var leaf = {
        aabb: box3_clone(aabb),
        parent: undefined,
        left: undefined,
        right: undefined,
        data: object,
        height: 0,
        isLeaf: true
    };
    
    // Fatten the AABB
    box3_expand_by_scalar(leaf.aabb, tree.fattening);
    
    if (tree.root == undefined) {
        tree.root = leaf;
        return leaf;
    }
    
    // Find best sibling
    var sibling = tree.root;
    while (!sibling.isLeaf) {
        var left = sibling.left;
        var right = sibling.right;
        
        var area = box3_get_surface_area(sibling.aabb);
        
        var combinedAABB = box3_clone(sibling.aabb);
        box3_union(combinedAABB, leaf.aabb);
        var combinedArea = box3_get_surface_area(combinedAABB);
        
        var cost = 2 * combinedArea;
        var inheritanceCost = 2 * (combinedArea - area);
        
        var costLeft;
        if (left.isLeaf) {
            var combinedLeft = box3_clone(leaf.aabb);
            box3_union(combinedLeft, left.aabb);
            costLeft = box3_get_surface_area(combinedLeft) + inheritanceCost;
        } else {
            var combinedLeft = box3_clone(leaf.aabb);
            box3_union(combinedLeft, left.aabb);
            var oldArea = box3_get_surface_area(left.aabb);
            var newArea = box3_get_surface_area(combinedLeft);
            costLeft = (newArea - oldArea) + inheritanceCost;
        }
        
        var costRight;
        if (right.isLeaf) {
            var combinedRight = box3_clone(leaf.aabb);
            box3_union(combinedRight, right.aabb);
            costRight = box3_get_surface_area(combinedRight) + inheritanceCost;
        } else {
            var combinedRight = box3_clone(leaf.aabb);
            box3_union(combinedRight, right.aabb);
            var oldArea = box3_get_surface_area(right.aabb);
            var newArea = box3_get_surface_area(combinedRight);
            costRight = (newArea - oldArea) + inheritanceCost;
        }
        
        if (cost < costLeft && cost < costRight) break;
        
        if (costLeft < costRight) sibling = left;
        else sibling = right;
    }
    
    // Create new parent
    var oldParent = sibling.parent;
    var newParent = {
        aabb: box3_clone(sibling.aabb),
        parent: oldParent,
        left: sibling,
        right: leaf,
        data: undefined,
        height: sibling.height + 1,
        isLeaf: false
    };
    box3_union(newParent.aabb, leaf.aabb);
    
    sibling.parent = newParent;
    leaf.parent = newParent;
    
    if (oldParent == undefined) {
        tree.root = newParent;
    } else {
        if (oldParent.left == sibling) oldParent.left = newParent;
        else oldParent.right = newParent;
    }
    
    // Refit and balance
    var node = leaf.parent;
    while (node != undefined) {
        node = __dynamic_aabb_tree_balance(tree, node);
        
        var l = node.left;
        var r = node.right;
        
        node.height = 1 + max(l.height, r.height);
        box3_copy(node.aabb, l.aabb);
        box3_union(node.aabb, r.aabb);
        
        node = node.parent;
    }
    
    return leaf;
}

/// @func dynamic_aabb_tree_remove(tree, leaf)
/// @desc Removes a leaf node from the tree.
/// @param {Struct} tree The tree
/// @param {Struct} leaf The leaf node to remove
function dynamic_aabb_tree_remove(tree, leaf) {
    if (leaf == tree.root) {
        tree.root = undefined;
        return;
    }
    
    var parent = leaf.parent;
    var grandParent = parent.parent;
    var sibling = (parent.left == leaf) ? parent.right : parent.left;
    
    if (grandParent != undefined) {
        if (grandParent.left == parent) grandParent.left = sibling;
        else grandParent.right = sibling;
        
        sibling.parent = grandParent;
        
        var node = grandParent;
        while (node != undefined) {
            node = __dynamic_aabb_tree_balance(tree, node);
            
            var l = node.left;
            var r = node.right;
            
            node.height = 1 + max(l.height, r.height);
            box3_copy(node.aabb, l.aabb);
            box3_union(node.aabb, r.aabb);
            
            node = node.parent;
        }
    } else {
        tree.root = sibling;
        sibling.parent = undefined;
    }
}

/// @func dynamic_aabb_tree_update(tree, leaf, aabb, force = false)
/// @desc Updates an object's position in the tree.
/// @param {Struct} tree The tree
/// @param {Struct} leaf The leaf node to update
/// @param {Array} aabb The new Box3
/// @param {Bool} [force] Whether to force an update even if within fattened AABB
/// @returns {Bool} Whether the tree was actually updated
function dynamic_aabb_tree_update(tree, leaf, aabb, force = false) {
    if (!force && box3_contains_box(leaf.aabb, aabb)) {
        return false;
    }
    
    var data = leaf.data;
    dynamic_aabb_tree_remove(tree, leaf);
    
    var newLeaf = dynamic_aabb_tree_insert(tree, data, aabb);
    
    // Copy new values back to the original leaf reference
    leaf.aabb = newLeaf.aabb;
    leaf.parent = newLeaf.parent;
    leaf.left = newLeaf.left;
    leaf.right = newLeaf.right;
    leaf.height = newLeaf.height;
    leaf.isLeaf = newLeaf.isLeaf;
    
    return true;
}

/// @func dynamic_aabb_tree_query_box(tree, box, results)
/// @desc Queries the tree for objects whose AABB intersects the given box.
/// @param {Struct} tree The tree
/// @param {Array<Real>} box The query box [minX, minY, minZ, maxX, maxY, maxZ]
/// @param {Array} results The array to store results in
function dynamic_aabb_tree_query_box(tree, box, results) {
    if (tree.root == undefined) return;
    
    var stack = [tree.root];
    while (array_length(stack) > 0) {
        var node = array_pop(stack);
        if (box3_intersects_box(node.aabb, box)) {
            if (node.isLeaf) {
                array_push(results, node.data);
            } else {
                array_push(stack, node.left);
                array_push(stack, node.right);
            }
        }
    }
}

/// @func dynamic_aabb_tree_query_sphere(tree, sphere, results)
/// @desc Queries the tree for objects whose AABB intersects the given sphere.
/// @param {Struct} tree The tree
/// @param {Array<Real>} sphere The query sphere [x, y, z, r]
/// @param {Array} results The array to store results in
function dynamic_aabb_tree_query_sphere(tree, sphere, results) {
    if (tree.root == undefined) return;
    
    var stack = [tree.root];
    while (array_length(stack) > 0) {
        var node = array_pop(stack);
        if (box3_intersects_sphere(node.aabb, sphere)) {
            if (node.isLeaf) {
                array_push(results, node.data);
            } else {
                array_push(stack, node.left);
                array_push(stack, node.right);
            }
        }
    }
}

/// @func dynamic_aabb_tree_query_frustum(tree, frustum, results)
/// @desc Queries the tree for objects whose AABB intersects the given frustum.
/// @param {Struct} tree The tree
/// @param {Array<Array<Real>>} frustum The query frustum
/// @param {Array} results The array to store results in
function dynamic_aabb_tree_query_frustum(tree, frustum, results) {
    if (tree.root == undefined) return;
    
    var stack = [tree.root];
    while (array_length(stack) > 0) {
        var node = array_pop(stack);
        if (frustum_intersects_box(frustum, node.aabb)) {
            if (node.isLeaf) {
                array_push(results, node.data);
            } else {
                array_push(stack, node.left);
                array_push(stack, node.right);
            }
        }
    }
}

/// @func dynamic_aabb_tree_query_ray(tree, ray, results)
/// @desc Queries the tree for objects whose AABB intersects the given ray.
/// @param {Struct} tree The tree
/// @param {Array<Real>} ray The query ray [ox, oy, oz, dx, dy, dz]
/// @param {Array} results The array to store results in
function dynamic_aabb_tree_query_ray(tree, ray, results) {
    if (tree.root == undefined) return;
    
    var stack = [tree.root];
    while (array_length(stack) > 0) {
        var node = array_pop(stack);
        if (ray_intersects_box(ray, node.aabb)) {
            if (node.isLeaf) {
                array_push(results, node.data);
            } else {
                array_push(stack, node.left);
                array_push(stack, node.right);
            }
        }
    }
}

/// @func dynamic_aabb_tree_intersect_ray(tree, ray)
/// @desc Finds the closest object intersection in the tree.
/// @param {Struct} tree The tree
/// @param {Array<Real>} ray The ray
/// @returns {Struct|Undefined} A struct with {object, distance} or undefined
function dynamic_aabb_tree_intersect_ray(tree, ray) {
    if (tree.root == undefined) return undefined;
    
    var closest = undefined;
    var stack = [tree.root];
    
    while (array_length(stack) > 0) {
        var node = array_pop(stack);
        var dist = ray_intersect_box(ray, node.aabb);
        
        if (dist != -1 && (closest == undefined || dist < closest.distance)) {
            if (node.isLeaf) {
                closest = { object: node.data, distance: dist };
            } else {
                array_push(stack, node.left);
                array_push(stack, node.right);
            }
        }
    }
    
    return closest;
}

/// @func dynamic_aabb_tree_clear(tree)
/// @desc Removes all objects from the tree.
/// @param {Struct} tree The tree
function dynamic_aabb_tree_clear(tree) {
    tree.root = undefined;
}

/// @func __dynamic_aabb_tree_balance(tree, node)
/// @desc Internal function to balance the tree using AVL-like rotations.
function __dynamic_aabb_tree_balance(tree, iA) {
    if (iA.isLeaf || iA.height < 2) return iA;
    
    var iB = iA.left;
    var iC = iA.right;
    var balance = iC.height - iB.height;
    
    // Rotate C up
    if (balance > 1) {
        var iF = iC.left;
        var iG = iC.right;
        
        iC.left = iA;
        iC.parent = iA.parent;
        iA.parent = iC;
        
        if (iC.parent != undefined) {
            if (iC.parent.left == iA) iC.parent.left = iC;
            else iC.parent.right = iC;
        } else {
            tree.root = iC;
        }
        
        if (iF.height > iG.height) {
            iC.right = iF;
            iA.right = iG;
            iG.parent = iA;
            box3_copy(iA.aabb, iB.aabb);
            box3_union(iA.aabb, iG.aabb);
            box3_copy(iC.aabb, iA.aabb);
            box3_union(iC.aabb, iF.aabb);
            
            iA.height = 1 + max(iB.height, iG.height);
            iC.height = 1 + max(iA.height, iF.height);
        } else {
            iC.right = iG;
            iA.right = iF;
            iF.parent = iA;
            box3_copy(iA.aabb, iB.aabb);
            box3_union(iA.aabb, iF.aabb);
            box3_copy(iC.aabb, iA.aabb);
            box3_union(iC.aabb, iG.aabb);
            
            iA.height = 1 + max(iB.height, iF.height);
            iC.height = 1 + max(iA.height, iG.height);
        }
        
        return iC;
    }
    
    // Rotate B up
    if (balance < -1) {
        var iD = iB.left;
        var iE = iB.right;
        
        iB.left = iA;
        iB.parent = iA.parent;
        iA.parent = iB;
        
        if (iB.parent != undefined) {
            if (iB.parent.left == iA) iB.parent.left = iB;
            else iB.parent.right = iB;
        } else {
            tree.root = iB;
        }
        
        if (iD.height > iE.height) {
            iB.right = iD;
            iA.left = iE;
            iE.parent = iA;
            box3_copy(iA.aabb, iC.aabb);
            box3_union(iA.aabb, iE.aabb);
            box3_copy(iB.aabb, iA.aabb);
            box3_union(iB.aabb, iD.aabb);
            
            iA.height = 1 + max(iC.height, iE.height);
            iB.height = 1 + max(iA.height, iD.height);
        } else {
            iB.right = iE;
            iA.left = iD;
            iD.parent = iA;
            box3_copy(iA.aabb, iC.aabb);
            box3_union(iA.aabb, iD.aabb);
            box3_copy(iB.aabb, iA.aabb);
            box3_union(iB.aabb, iE.aabb);
            
            iA.height = 1 + max(iC.height, iD.height);
            iB.height = 1 + max(iA.height, iE.height);
        }
        
        return iB;
    }
    
    return iA;
}
