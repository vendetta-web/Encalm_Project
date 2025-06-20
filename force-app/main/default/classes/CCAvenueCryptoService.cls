public with sharing class CCAvenueCryptoService {
        
    public static String encrypt(String plainText, String key) {
        // Step 1: Generate 128-bit (16-byte) MD5 hash of the key
        Blob keyBlob = Crypto.generateDigest('MD5', Blob.valueOf(key));
		system.debug('plaintext: ' + plainText);
        // Step 2: Fixed 16-byte IV as decimal (equivalent of 0x00 to 0x0F)
        List<Integer> ivInts = new List<Integer>{
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10, 11,
            12, 13, 14, 15
        };
        // Convert integers to characters and form the IV string
        String ivString = '';
        for (Integer i : ivInts) {
            ivString += String.fromCharArray(new List<Integer>{i});
        }
        Blob ivBlob = Blob.valueOf(ivString);

        // Step 3: Apply PKCS#7 padding
        Blob plainBlob = Blob.valueOf(plainText);
        Blob paddedBlob = applyPKCS7Padding(plainBlob, 16);

        // Step 4: Encrypt using AES-128-CBC
        Blob encryptedBlob = Crypto.encrypt('AES128', keyBlob, ivBlob, paddedBlob);

        // Step 5: Convert to hex
        return EncodingUtil.convertToHex(encryptedBlob).toLowerCase();
    }

    private static Blob applyPKCS7Padding(Blob input, Integer blockSize) {
        String inputStr = input.toString();
        Integer padLen = blockSize - Math.mod(inputStr.length(), blockSize);
        
        // Generate padding string manually
        String padChar = String.fromCharArray(new List<Integer>{padLen});
        String padding = '';
        for (Integer i = 0; i < padLen; i++) {
            padding += padChar;
        }

        return Blob.valueOf(inputStr + padding);
    }

    public static String decrypt(String encryptedHex, String key) {
        // Step 1: Validate the hex string (must be even-length)
        Integer length = encryptedHex.length();
        if (String.isEmpty(encryptedHex) || length == 0 || length / 2 != Math.floor(length / 2)) {
            throw new IllegalArgumentException('Invalid hexadecimal string length');
        }

        // Step 2: Convert the hex string to a Blob
        Blob encryptedBlob;
        
            encryptedBlob = EncodingUtil.convertFromHex(encryptedHex.replaceAll('[^0-9a-fA-F]', ''));
        

        // Step 3: Generate 128-bit MD5 hash of the key (key should be 16 bytes)
        Blob keyBlob = Crypto.generateDigest('MD5', Blob.valueOf(key));

        List<Integer> ivInts = new List<Integer>{
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10, 11,
            12, 13, 14, 15
        };
        // Convert integers to characters and form the IV string
        String ivString = '';
        for (Integer i : ivInts) {
            ivString += String.fromCharArray(new List<Integer>{i});
        }
        Blob ivBlob = Blob.valueOf(ivString);

        // Step 5: Decrypt the data using AES-128-CBC
        Blob decryptedBlob = Crypto.decrypt('AES128', keyBlob, ivBlob, encryptedBlob);

        // Step 6: Remove PKCS#7 padding
        return removePKCS7Padding(decryptedBlob);
    }

    private static String removePKCS7Padding(Blob decryptedBlob) {
        String decryptedStr = decryptedBlob.toString();
        system.debug('decryptedStr: '  + decryptedStr);
        // Get the padding length, which is the last byte of the decrypted text
        Integer padValue = (Integer)decryptedStr.charAt(decryptedStr.length() - 1);
        // Return the original data without the padding
        return decryptedStr; //.substring(0, decryptedStr.length() - padValue);
    }

}