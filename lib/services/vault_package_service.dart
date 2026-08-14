import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'crypto_service.dart';

class VaultPackageService {
  final String internalDbPath;
  final String internalSaltPath;
  final CryptoService _cryptoService = CryptoService();

  VaultPackageService({
    required this.internalDbPath,
    required this.internalSaltPath,
  });

  /// Extracts and decrypts the given .cvault file to the internal working directory
  Future<bool> unpackVault(String cvaultPath, String masterPassword) async {
    final cvaultFile = File(cvaultPath);
    if (!await cvaultFile.exists()) {
      throw Exception("El archivo no existe en la ruta: $cvaultPath");
    }

    try {
      final fileBytes = await cvaultFile.readAsBytes();
      
      // If the file is smaller than the salt size (16 bytes), it's invalid
      if (fileBytes.length <= 16) {
        throw Exception("El archivo es demasiado pequeño o está corrupto.");
      }
      
      // 1. Extract the 16-byte salt from the beginning of the file
      final saltBytes = Uint8List.sublistView(fileBytes, 0, 16);
      
      // 2. Extract the encrypted payload
      final encryptedBytes = fileBytes.sublist(16);
      
      // 3. Derive the encryption key using the master password and salt
      final key = await _cryptoService.deriveMasterKey(
        masterPassword: masterPassword,
        salt: saltBytes,
      );
      
      // 4. Decrypt the payload
      final decryptedBytes = await _cryptoService.decryptData(encryptedBytes, key);
      
      // 5. Unzip the decrypted payload
      final archive = ZipDecoder().decodeBytes(decryptedBytes);

      bool foundDb = false;
      bool foundSalt = false;
      List<String> foundFiles = [];

      for (final file in archive) {
        if (file.isFile) {
          foundFiles.add(file.name);
          if (file.name == 'app_vault.db' || file.name.endsWith('.db')) {
            await File(internalDbPath).writeAsBytes(file.content as List<int>);
            foundDb = true;
          } else if (file.name == 'vault.salt' || file.name.endsWith('.salt')) {
            await File(internalSaltPath).writeAsBytes(file.content as List<int>);
            foundSalt = true;
          }
        }
      }
      
      if (!foundDb || !foundSalt) {
        throw Exception("Faltan archivos internos. Encontrados: $foundFiles");
      }
      
      return true;
    } catch (e) {
      // The decryption exception will be caught here if the password is wrong
      throw Exception('Contraseña incorrecta o archivo dañado.');
    }
  }

  /// Packages and encrypts the internal files into the specified .cvault file
  Future<void> packVault(String cvaultPath, String masterPassword) async {
    final dbFile = File(internalDbPath);
    final saltFile = File(internalSaltPath);

    if (!await dbFile.exists() || !await saltFile.exists()) {
      throw Exception('Internal vault files do not exist.');
    }

    try {
      // 1. Zip the internal files
      final archive = Archive();
      final dbBytes = await dbFile.readAsBytes();
      final saltBytes = await saltFile.readAsBytes();
      
      archive.addFile(ArchiveFile('app_vault.db', dbBytes.length, dbBytes));
      archive.addFile(ArchiveFile('vault.salt', saltBytes.length, saltBytes));
      
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        throw Exception("Failed to encode zip.");
      }
      
      // 2. Derive key from password and existing salt
      final key = await _cryptoService.deriveMasterKey(
        masterPassword: masterPassword,
        salt: saltBytes,
      );
      
      // 3. Encrypt the zip bytes
      final encryptedZipBytes = await _cryptoService.encryptData(zipBytes, key);
      
      // 4. Prepend the salt to the file and save
      final finalBytes = BytesBuilder();
      finalBytes.add(saltBytes); // 16 bytes
      finalBytes.add(encryptedZipBytes);
      
      await File(cvaultPath).writeAsBytes(finalBytes.toBytes());
    } catch (e) {
      throw Exception('Failed to pack vault: $e');
    }
  }
}
