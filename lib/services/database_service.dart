import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_service.dart';

class EncryptedDatabaseService {
  Database? _db;
  final CryptoService _cryptoService = CryptoService();

  Database get db {
    if (_db == null || !_db!.isOpen) {
      throw Exception('La base de datos está bloqueada. Ingrese la Master Password.');
    }
    return _db!;
  }

  Future<String> get _dbPath async {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, 'app_vault.db');
  }

  Future<String> get _saltPath async {
    final path = await _dbPath;
    final dir = dirname(path);
    return join(dir, 'vault.salt');
  }

  Future<String> get dbPath => _dbPath;
  Future<String> get saltPath => _saltPath;

  /// Intenta abrir la BD. La encriptación real está manejada por VaultPackageService en el archivo .cvault.
  Future<bool> unlockDatabase(String masterPassword) async {
    try {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final path = await dbPath;

      // Ensure the salt file exists, as VaultPackageService needs it when packing.
      await _getOrCreateSalt();

      // Abrir la BD (es temporal y en texto plano, pero solo existe mientras está desbloqueada)
      _db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createTables,
        ),
      );

      // Verificación de lectura rápida
      await _db!.rawQuery('SELECT count(*) FROM sqlite_master;');
      return true;
    } catch (e) {
      await closeDatabase();
      throw Exception('Database error: $e');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabla de Credenciales Generales
    await db.execute('''
      CREATE TABLE credentials (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT NOT NULL,
        auth_type TEXT NOT NULL,
        secret_payload TEXT NOT NULL
      )
    ''');

    // Tabla de Carpetas/Grupos
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_folder_id TEXT,
        default_credential_id TEXT
      )
    ''');

    // Tabla de Servidores
    await db.execute('''
      CREATE TABLE servers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL,
        folder_id TEXT,
        credential_id TEXT,
        FOREIGN KEY (folder_id) REFERENCES folders (id) ON DELETE SET NULL,
        FOREIGN KEY (credential_id) REFERENCES credentials (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<Uint8List> _getOrCreateSalt() async {
    final sPath = await saltPath;
    final saltFile = File(sPath);

    if (await saltFile.exists()) {
      return await saltFile.readAsBytes();
    } else {
      final newSalt = _cryptoService.generateRandomSalt();
      await saltFile.writeAsBytes(newSalt);
      return newSalt;
    }
  }

  Future<bool> hasSaltFile() async {
    final sPath = await saltPath;
    final saltFile = File(sPath);
    return await saltFile.exists();
  }



  Future<void> closeDatabase() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
