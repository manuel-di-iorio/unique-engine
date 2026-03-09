//function ueUuid() {
    //gml_pragma("forceinline");
    //var hex = "0123456789abcdef";
    //var uuid = "";
    //var r;
//
    //for (var i = 0; i < 36; i++) {
        //// Inserisci dash alle posizioni fisse
        //if (i == 8 || i == 13 || i == 18 || i == 23) {
            //uuid += "-";
            //continue;
        //}
        //// Versione 4 a posizione 14
        //if (i == 14) {
            //uuid += "4";
            //continue;
        //}
        //// Genera un valore random da 0 a 15
        //r = irandom(15);
//
        //// Posizione 19: imposta la variante (10xx)
        //if (i == 19) {
            //r = (r & 0x3) | 0x8;
        //}
        //uuid += string_char_at(hex, r + 1);
    //}
//
    //return uuid;
//}

/// @function ueUuid()
/// @description Generates a RFC 4122 compliant UUID v4.
/// @return {string} UUID v4
function ueUuid() {
    gml_pragma("forceinline");

    // Precomputed hex ASCII codes
    static HEX = [
        ord("0"), ord("1"), ord("2"), ord("3"),
        ord("4"), ord("5"), ord("6"), ord("7"),
        ord("8"), ord("9"), ord("a"), ord("b"),
        ord("c"), ord("d"), ord("e"), ord("f")
    ];

    // Reusable output buffer
    static OUT = buffer_create(36, buffer_fixed, 1);

    buffer_seek(OUT, buffer_seek_start, 0);

    for (var i = 0; i < 16; i++) {
        // Insert dashes
        if (i == 4 || i == 6 || i == 8 || i == 10) {
            buffer_write(OUT, buffer_u8, ord("-"));
        }

        var b = irandom(255);

        // Set UUID version (byte 6)
        if (i == 6) {
            b = (b & $0F) | $40;
        }

        // Set UUID variant (byte 8)
        if (i == 8) {
            b = (b & $3F) | $80;
        }

        // Convert byte to hex
        buffer_write(OUT, buffer_u8, HEX[(b >> 4) & $F]);
        buffer_write(OUT, buffer_u8, HEX[b & $F]);
    }

    buffer_seek(OUT, buffer_seek_start, 0);
    return buffer_read(OUT, buffer_string);
}