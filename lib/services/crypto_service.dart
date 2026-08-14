import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  // Derivar clave de 256 bits a partir de la Master Password usando Argon2id
  Future<Uint8List> deriveMasterKey({
    required String masterPassword,
    required Uint8List salt,
  }) async {
    final algorithm = Argon2id(
      parallelism: 2,
      memory: 65536, // 64 MB
      iterations: 3,
      hashLength: 32, // 256 bits
    );

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: masterPassword,
      nonce: salt,
    );

    return Uint8List.fromList(await secretKey.extractBytes());
  }

  // Generador de Salt aleatorio para la primera configuración
  Uint8List generateRandomSalt([int length = 16]) {
    final secretKey = SecretKeyData.random(length: length);
    return Uint8List.fromList(secretKey.bytes);
  }

  Future<List<int>> encryptData(List<int> data, Uint8List key) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKeyData(key);
    
    // AES-GCM recommended nonce size is 12 bytes
    final nonce = algorithm.newNonce();
    
    final secretBox = await algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );
    
    return secretBox.concatenation();
  }

  Future<List<int>> decryptData(List<int> encryptedData, Uint8List key) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKeyData(key);
    
    final secretBox = SecretBox.fromConcatenation(
      encryptedData,
      nonceLength: algorithm.nonceLength,
      macLength: algorithm.macAlgorithm.macLength,
    );
    
    return await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
  }
}
