/**
 * AES Crypt - Encrypt a string or buffer by using AES in CBC mode
 * @license MIT
 */
function AES() constructor {
    
    // --- AES Constants ---
    static __sbox = [
        0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
        0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
        0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
        0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
        0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
        0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
        0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
        0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
        0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
        0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
        0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
        0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
        0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
        0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
        0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
        0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
    ];

    static __rsbox = [
        0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
        0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
        0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
        0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
        0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
        0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
        0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
        0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
        0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
        0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
        0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
        0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
        0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
        0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
        0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
        0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
    ];

    static __rcon = [
        0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36
    ];

    // --- Helper Functions ---

    static __getKeyBytes = function(key) {
        var keyBuf = buffer_create(16, buffer_fixed, 1);
        if (is_string(key)) {
            for (var i = 0; i < 16; i++) {
                if (i < string_byte_length(key)) {
                    buffer_write(keyBuf, buffer_u8, string_byte_at(key, i + 1));
                } else {
                    buffer_write(keyBuf, buffer_u8, 0);
                }
            }
        } else {
            // Assume buffer
            buffer_copy(key, 0, min(buffer_get_size(key), 16), keyBuf, 0);
        }
        var bytes = array_create(16);
        buffer_seek(keyBuf, buffer_seek_start, 0);
        for(var i=0; i<16; i++) bytes[i] = buffer_read(keyBuf, buffer_u8);
        buffer_delete(keyBuf);
        return bytes;
    };

    static __keyExpansion = function(key) {
        var w = array_create(176); // 4 * (Nr + 1) * 4 bytes = 176 for AES-128 (Nr=10)
        
        for (var i = 0; i < 16; i++) {
            w[i] = key[i];
        }

        var temp = array_create(4);
        var i = 16;
        while (i < 176) {
            for(var t=0; t<4; t++) temp[t] = w[i - 4 + t];

            if (i % 16 == 0) {
                // RotWord
                var k = temp[0];
                temp[0] = temp[1];
                temp[1] = temp[2];
                temp[2] = temp[3];
                temp[3] = k;

                // SubWord
                for(var t=0; t<4; t++) temp[t] = __sbox[temp[t]];

                // Rcon
                temp[0] = temp[0] ^ __rcon[i / 16];
            }

            for(var t=0; t<4; t++) {
                w[i] = w[i - 16] ^ temp[t];
                i++;
            }
        }
        return w;
    };

    static __subBytes = function(state) {
        for (var i = 0; i < 16; i++) {
            state[i] = __sbox[state[i]];
        }
    };

    static __shiftRows = function(state) {
        var temp = array_create(16);
        array_copy(temp, 0, state, 0, 16);
        
        // Row 0: No shift
        // Row 1: Shift left 1
        state[1] = temp[5]; state[5] = temp[9]; state[9] = temp[13]; state[13] = temp[1];
        // Row 2: Shift left 2
        state[2] = temp[10]; state[6] = temp[14]; state[10] = temp[2]; state[14] = temp[6];
        // Row 3: Shift left 3
        state[3] = temp[15]; state[7] = temp[3]; state[11] = temp[7]; state[15] = temp[11];
    };

    static __gmul2 = function(x) {
        return ((x << 1) & 0xFF) ^ ((x & 0x80) ? 0x1b : 0x00);
    };
    
    static __gmul3 = function(x) {
        return __gmul2(x) ^ x;
    };

    static __mixColumns = function(state) {
        var temp = array_create(16);
        array_copy(temp, 0, state, 0, 16);

        for (var c = 0; c < 4; c++) {
            var i = c * 4;
            var s0 = temp[i];
            var s1 = temp[i+1];
            var s2 = temp[i+2];
            var s3 = temp[i+3];

            state[i]   = __gmul2(s0) ^ __gmul3(s1) ^ s2 ^ s3;
            state[i+1] = s0 ^ __gmul2(s1) ^ __gmul3(s2) ^ s3;
            state[i+2] = s0 ^ s1 ^ __gmul2(s2) ^ __gmul3(s3);
            state[i+3] = __gmul3(s0) ^ s1 ^ s2 ^ __gmul2(s3);
        }
    };

    static __addRoundKey = function(state, w, rnd) {
        for (var i = 0; i < 16; i++) {
            state[i] = state[i] ^ w[rnd * 16 + i];
        }
    };

    static __cipher = function(block, w) {
        var state = array_create(16);
        array_copy(state, 0, block, 0, 16);

        __addRoundKey(state, w, 0);

        for (var rnd = 1; rnd < 10; rnd++) {
            __subBytes(state);
            __shiftRows(state);
            __mixColumns(state);
            __addRoundKey(state, w, rnd);
        }

        __subBytes(state);
        __shiftRows(state);
        __addRoundKey(state, w, 10);

        return state;
    };

    // --- Inverse Functions ---

    static __invSubBytes = function(state) {
        for (var i = 0; i < 16; i++) {
            state[i] = __rsbox[state[i]];
        }
    };

    static __invShiftRows = function(state) {
        var temp = array_create(16);
        array_copy(temp, 0, state, 0, 16);

        // Row 0: No shift
        // Row 1: Shift right 1
        state[1] = temp[13]; state[5] = temp[1]; state[9] = temp[5]; state[13] = temp[9];
        // Row 2: Shift right 2
        state[2] = temp[10]; state[6] = temp[14]; state[10] = temp[2]; state[14] = temp[6];
        // Row 3: Shift right 3
        state[3] = temp[7]; state[7] = temp[11]; state[11] = temp[15]; state[15] = temp[3];
    };

    static __gmul9 = function(x) { return __gmul2(__gmul2(__gmul2(x))) ^ x; };
    static __gmul11 = function(x) { return __gmul2(__gmul2(__gmul2(x)) ^ x) ^ x; };
    static __gmul13 = function(x) { return __gmul2(__gmul2(__gmul2(x) ^ x)) ^ x; };
    static __gmul14 = function(x) { return __gmul2(__gmul2(__gmul2(x) ^ x) ^ x); };

    static __invMixColumns = function(state) {
        var temp = array_create(16);
        array_copy(temp, 0, state, 0, 16);

        for (var c = 0; c < 4; c++) {
            var i = c * 4;
            var s0 = temp[i];
            var s1 = temp[i+1];
            var s2 = temp[i+2];
            var s3 = temp[i+3];

            state[i]   = __gmul14(s0) ^ __gmul11(s1) ^ __gmul13(s2) ^ __gmul9(s3);
            state[i+1] = __gmul9(s0) ^ __gmul14(s1) ^ __gmul11(s2) ^ __gmul13(s3);
            state[i+2] = __gmul13(s0) ^ __gmul9(s1) ^ __gmul14(s2) ^ __gmul11(s3);
            state[i+3] = __gmul11(s0) ^ __gmul13(s1) ^ __gmul9(s2) ^ __gmul14(s3);
        }
    };

    static __invCipher = function(block, w) {
        var state = array_create(16);
        array_copy(state, 0, block, 0, 16);

        __addRoundKey(state, w, 10);

        for (var rnd = 9; rnd > 0; rnd--) {
            __invShiftRows(state);
            __invSubBytes(state);
            __addRoundKey(state, w, rnd);
            __invMixColumns(state);
        }

        __invShiftRows(state);
        __invSubBytes(state);
        __addRoundKey(state, w, 0);

        return state;
    };

    // --- Public API ---

    /**
     * Encrypts a buffer using AES-128 CBC mode.
     * @param {Id.Buffer} buffer The input buffer containing data to encrypt.
     * @param {String|Id.Buffer} key The encryption key (16 bytes). If a string is provided, it will be padded or truncated to 16 bytes.
     * @returns {Id.Buffer} A new buffer containing the encrypted data (IV + Ciphertext). Remember to delete this buffer when done!
     */
    static encrypt = function(buffer, key) {
        var keyBytes = __getKeyBytes(key);
        var w = __keyExpansion(keyBytes);
        
        var size = buffer_get_size(buffer);
        var paddedSize = ceil((size + 1) / 16) * 16; // PKCS7 padding needs at least 1 byte
        
        var outBuffer = buffer_create(paddedSize, buffer_fixed, 1);
        var block = array_create(16);
        
        var iv = array_create(16);
        for(var i=0; i<16; i++) iv[i] = irandom(255);
        
        // Write IV to output (resize output to include IV)
        buffer_resize(outBuffer, paddedSize + 16);
        buffer_seek(outBuffer, buffer_seek_start, 0);
        for(var i=0; i<16; i++) buffer_write(outBuffer, buffer_u8, iv[i]);
        
        var prevBlock = iv;
        
        buffer_seek(buffer, buffer_seek_start, 0);
        
        for (var offset = 0; offset < size; offset += 16) {
            // Read block
            for (var i = 0; i < 16; i++) {
                if (offset + i < size) {
                    block[i] = buffer_read(buffer, buffer_u8);
                } else {
                    // Padding (PKCS7)
                    var pad = 16 - (size % 16);
                    block[i] = pad;
                }
            }
            
            // CBC: XOR with prev
            for(var i=0; i<16; i++) block[i] = block[i] ^ prevBlock[i];
            
            var encryptedBlock = __cipher(block, w);
            
            for(var i=0; i<16; i++) buffer_write(outBuffer, buffer_u8, encryptedBlock[i]);
            prevBlock = encryptedBlock;
        }
        
        // Handle full padding block if needed
        if (size % 16 == 0) {
            var pad = 16;
            for(var i=0; i<16; i++) block[i] = pad;
            for(var i=0; i<16; i++) block[i] = block[i] ^ prevBlock[i];
            var encryptedBlock = __cipher(block, w);
            for(var i=0; i<16; i++) buffer_write(outBuffer, buffer_u8, encryptedBlock[i]);
        }
        
        return outBuffer;
    };

    /**
     * Decrypts a buffer using AES-128 CBC mode.
     * @param {Id.Buffer} buffer The input buffer containing encrypted data (must include IV at the start).
     * @param {String|Id.Buffer} key The decryption key (must match the encryption key).
     * @returns {Id.Buffer} A new buffer containing the decrypted data, or undefined if the input is invalid. Remember to delete this buffer when done!
     */
    static decrypt = function(buffer, key) {
        var keyBytes = __getKeyBytes(key);
        var w = __keyExpansion(keyBytes);
        
        var size = buffer_get_size(buffer);
        if (size < 16) return undefined; // Error: too short (must have IV)
        
        var outBuffer = buffer_create(size - 16, buffer_fixed, 1); // Minus IV
        var block = array_create(16);
        var iv = array_create(16);
        
        buffer_seek(buffer, buffer_seek_start, 0);
        for(var i=0; i<16; i++) iv[i] = buffer_read(buffer, buffer_u8);
        
        var prevBlock = iv;
        var currentBlock = array_create(16);
        
        for (var offset = 16; offset < size; offset += 16) {
            for(var i=0; i<16; i++) currentBlock[i] = buffer_read(buffer, buffer_u8);
            
            var decryptedBlock = __invCipher(currentBlock, w);
            
            // CBC: XOR with prev
            for(var i=0; i<16; i++) decryptedBlock[i] = decryptedBlock[i] ^ prevBlock[i];
            
            // Write to output (we might overwrite padding later, or truncate)
            for(var i=0; i<16; i++) buffer_write(outBuffer, buffer_u8, decryptedBlock[i]);
            
            array_copy(prevBlock, 0, currentBlock, 0, 16);
        }
        
        // Remove padding
        // Check last byte of output
        var outSize = buffer_tell(outBuffer);
        if (outSize > 0) {
            buffer_seek(outBuffer, buffer_seek_relative, -1);
            var pad = buffer_read(outBuffer, buffer_u8);
            if (pad > 0 && pad <= 16) {
                // Verify padding?
                // Assume correct padding
                buffer_resize(outBuffer, outSize - pad);
            }
        }
        
        buffer_seek(outBuffer, buffer_seek_start, 0);
        return outBuffer;
    };
    
    /**
     * Encrypts a string and returns a Base64 encoded string.
     * @param {String} str The string to encrypt.
     * @param {String|Id.Buffer} key The encryption key.
     * @returns {String} The encrypted data as a Base64 string.
     */
    static encryptString = function(str, key) {
        var buf = buffer_create(string_byte_length(str), buffer_fixed, 1);
        buffer_write(buf, buffer_text, str);
        var encBuf = encrypt(buf, key);
        var b64 = buffer_base64_encode(encBuf, 0, buffer_get_size(encBuf));
        buffer_delete(buf);
        buffer_delete(encBuf);
        return b64;
    };
    
    /**
     * Decrypts a Base64 encoded string.
     * @param {String} str The Base64 string to decrypt.
     * @param {String|Id.Buffer} key The decryption key.
     * @returns {String} The decrypted string, or empty string if decryption fails.
     */
    static decryptString = function(str, key) {
        var encBuf = buffer_base64_decode(str);
        var decBuf = decrypt(encBuf, key);
        if (decBuf == undefined) return "";
        var res = buffer_read(decBuf, buffer_text);
        buffer_delete(encBuf);
        buffer_delete(decBuf);
        return res;
    };
}