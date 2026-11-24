import 'dart:convert';
import 'dart:typed_data';
import 'package:argon2/argon2.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoService {
  static Uint8List deriveKey(String masterPassword, Uint8List salt) {
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      iterations: 3,
      memory: 65536,
      lanes: 4,
    );
    final argon2 = Argon2BytesGenerator()..init(parameters);
    final out = Uint8List(32);
    argon2.generateBytes(utf8.encode(masterPassword), out, 0, out.length);
    return out;
  }

  static String encryptJson(Map<String, dynamic> data, Uint8List key) {
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    final cipher = encrypter.encrypt(jsonEncode(data), iv: iv);
    return '${base64Encode(iv.bytes)}:${cipher.base64}';
  }

  static Map<String, dynamic> decryptJson(String blob, Uint8List key) {
    final parts = blob.split(':');
    final iv = enc.IV(base64Decode(parts[0]));
    final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
    final plain = encrypter.decrypt(enc.Encrypted.fromBase64(parts[1]), iv: iv);
    return jsonDecode(plain) as Map<String, dynamic>;
  }

  static Uint8List randomSalt() {
    return Uint8List.fromList(List.generate(16, (_) => DateTime.now().microsecondsSinceEpoch & 0xff));
  }
}