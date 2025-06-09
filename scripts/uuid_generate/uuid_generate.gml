function uuid_generate() {
    var hex = "0123456789abcdef";
    var uuid = "";
    var r;

    for (var i = 0; i < 36; i++) {
        // Inserisci trattini alle posizioni fisse
        if (i == 8 || i == 13 || i == 18 || i == 23) {
            uuid += "-";
            continue;
        }
        // Versione 4 a posizione 14
        if (i == 14) {
            uuid += "4";
            continue;
        }
        // Genera un valore random da 0 a 15
        r = irandom(15);

        // Posizione 19: imposta la variante (10xx)
        if (i == 19) {
            r = (r & 0x3) | 0x8;
        }
        uuid += string_char_at(hex, r + 1);
    }

    return uuid;
}