# UeParticleType

`UeParticleType` definisce le proprietà e il comportamento di una singola particella. È ispirato al sistema `part_type_*` di GameMaker ma modernizzato per Unique Engine con un'API fluente.

## Costruttore

```gml
var type = new UeParticleType();
```

## Metodi

### setLife
Imposta la durata minima e massima della particella in frame/ticks.
```gml
type.setLife(min, max);
```

### setSpeed
Imposta la velocità minima e massima, e opzionalmente un incremento per frame.
```gml
type.setSpeed(min, max, [incr]);
```

### setDirection
Imposta l'intervallo di direzione (in gradi) per il movimento iniziale.
```gml
type.setDirection(min, max);
```

### setSize
Imposta la dimensione minima e massima, e opzionalmente un incremento per frame.
```gml
type.setSize(min, max, [incr]);
```

### setAlpha
Imposta la trasparenza della particella. Può essere un valore fisso o una transizione tra tre punti (inizio, metà, fine).
```gml
type.setAlpha(start, [middle], [end]);
```

### setColor
Imposta il colore della particella. Può essere un colore fisso (`c_white`) o una transizione tra tre colori.
```gml
type.setColor(start, [middle], [end]);
```

### setGravity
Imposta la gravità e la sua direzione (270 è verso il basso).
```gml
type.setGravity(amount, [direction]);
```

### setRotation
Imposta la rotazione iniziale (min, max) e l'incremento rotazionale per frame.
```gml
type.setRotation(min, max, [incr]);
```

### setSprite
Imposta lo sprite e il frame da utilizzare per la particella.
```gml
type.setSprite(sprite, [frame]);
```

## Esempio

```gml
var fire = new UeParticleType()
    .setLife(30, 60)
    .setSpeed(1, 2, 0.05)
    .setDirection(80, 100)
    .setSize(0.5, 1, -0.01)
    .setColor(c_orange, c_red, c_black)
    .setAlpha(1, 0.5, 0)
    .setGravity(0.1, 90);
```
