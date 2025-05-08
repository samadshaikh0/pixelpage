import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _secretKey = dotenv.env['SECRETKEY'] ?? '';
final _ivKey = dotenv.env['IVKEY'] ?? '';

Map<String, dynamic>? decryptQRData(String encryptedBase64) {
  try {
    if (_secretKey.length != 16 || _ivKey.length != 16) {
      throw Exception('Keys must be exactly 16 characters long.');
    }

    final key = encrypt.Key.fromUtf8(_secretKey);
    final iv = encrypt.IV.fromUtf8(_ivKey);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);

    print('Decrypted JSON: $decrypted');

    return jsonDecode(decrypted);
  } catch (e) {
    print('Decryption error: $e');
    return null;
  }
}
