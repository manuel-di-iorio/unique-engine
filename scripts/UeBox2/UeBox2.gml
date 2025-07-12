/// Rappresenta un box 2D allineato agli assi (AABB), con limiti min e max in 2D.
/// @MissingDoc
function UeBox2(_min = new UeVector2(infinity, infinity), _max = new UeVector2(-infinity, -infinity)) constructor {
    self.min = _min;
    self.max = _max;

    /// Imposta i limiti del box
    function set(_min, _max) {
        self.min.copy(_min);
        self.max.copy(_max);
        return self;
    }

    /// Rende il box vuoto (non contiene alcun punto)
    function makeEmpty() {
        self.min.set(+infinity, +infinity);
        self.max.set(-infinity, -infinity);
        return self;
    }

    /// Verifica se il box è vuoto (nessuna area)
    function isEmpty() {
        return self.max.x < self.min.x || self.max.y < self.min.y;
    }

    /// Imposta il box da una lista di punti (Vector2)
    function setFromPoints(points) {
        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            expandByPoint(points[i]);
        }
        return self;
    }

    /// Imposta da centro e dimensione
    function setFromCenterAndSize(center, size) {
        var half = size.clone().scale(0.5);
        self.min.copy(center).sub(half);
        self.max.copy(center).add(half);
        return self;
    }

    /// Clona questo box
    function clone() {
        return variable_clone(self);
    }

    /// Copia i limiti da un altro box
    function copy(box) {
        self.min.copy(box.min);
        self.max.copy(box.max);
        return self;
    }

    /// Espande il box per includere un punto
    function expandByPoint(point) {
        self.min.x = min(self.min.x, point.x);
        self.min.y = min(self.min.y, point.y);
        self.max.x = max(self.max.x, point.x);
        self.max.y = max(self.max.y, point.y);
        return self;
    }

    /// Espande il box di un valore fisso in ogni direzione
    function expandByScalar(scalar) {
        self.min.x -= scalar;
        self.min.y -= scalar;
        self.max.x += scalar;
        self.max.y += scalar;
        return self;
    }

    /// Espande il box in base ad un vettore (in entrambe le direzioni)
    function expandByVector(vec) {
        self.min.sub(vec);
        self.max.add(vec);
        return self;
    }

    /// Verifica se il punto è dentro il box
    function containsPoint(point) {
        return (
            point.x >= self.min.x && point.x <= self.max.x &&
            point.y >= self.min.y && point.y <= self.max.y
        );
    }

    /// Verifica se un altro box è completamente contenuto
    function containsBox(box) {
        return (
            self.min.x <= box.min.x && box.max.x <= self.max.x &&
            self.min.y <= box.min.y && box.max.y <= self.max.y
        );
    }

    /// Calcola l'intersezione tra due box (aggiorna questo box)
    function intersect(box) {
        self.min.x = max(self.min.x, box.min.x);
        self.min.y = max(self.min.y, box.min.y);
        self.max.x = min(self.max.x, box.max.x);
        self.max.y = min(self.max.y, box.max.y);

        if (isEmpty()) makeEmpty();
        return self;
    }

    /// Verifica se due box si intersecano
    function intersectsBox(box) {
        return !(
            box.max.x < self.min.x || box.min.x > self.max.x ||
            box.max.y < self.min.y || box.min.y > self.max.y
        );
    }

    /// Unisce questo box con un altro (espandendo i limiti)
    function union(box) {
        self.min.x = min(self.min.x, box.min.x);
        self.min.y = min(self.min.y, box.min.y);
        self.max.x = max(self.max.x, box.max.x);
        self.max.y = max(self.max.y, box.max.y);
        return self;
    }

    /// Ritorna il centro del box
    function getCenter(target = new UeVector2()) {
        return target.copy(self.min).add(self.max).scale(0.5);
    }

    /// Ritorna larghezza e altezza
    function getSize(target = new UeVector2()) {
        return target.copy(self.max).sub(self.min);
    }

    /// Ritorna un punto normalizzato (0..1) rispetto ai limiti del box
    function getParameter(point, target = new UeVector2()) {
        target.x = (point.x - self.min.x) / (self.max.x - self.min.x);
        target.y = (point.y - self.min.y) / (self.max.y - self.min.y);
        return target;
    }

    /// Clampa un punto ai limiti del box (target opzionale)
    function clampPoint(point, target = new UeVector2()) {
        target.x = clamp(point.x, self.min.x, self.max.x);
        target.y = clamp(point.y, self.min.y, self.max.y);
        return target;
    }

    /// Distanza minima tra punto e box (0 se dentro)
    function distanceToPoint(point) {
        var clamped = clampPoint(point);
        return clamped.distanceTo(point);
    }

    /// Sposta il box nello spazio 2D
    function translate(offset) {
        self.min.add(offset);
        self.max.add(offset);
        return self;
    }

    /// Confronta due box
    function equals(box) {
        return self.min.equals(box.min) && self.max.equals(box.max);
    }
}
