import '../models/credential.dart';
import '../models/folder.dart';
import '../models/server.dart';
import '../services/database_service.dart';

class VaultRepository {
  final EncryptedDatabaseService _dbService;

  VaultRepository(this._dbService);

  // --- Folders ---

  Future<List<Folder>> getFolders() async {
    final db = _dbService.db;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  Future<void> createFolder(Folder folder) async {
    final db = _dbService.db;
    await db.insert('folders', folder.toMap());
  }

  Future<void> updateFolder(Folder folder) async {
    final db = _dbService.db;
    await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> deleteFolder(String id) async {
    final db = _dbService.db;
    // Servers with this folder_id will have their folder_id set to NULL due to ON DELETE SET NULL
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // --- Servers ---

  Future<List<Server>> getServers({String? folderId}) async {
    final db = _dbService.db;
    List<Map<String, dynamic>> maps;
    if (folderId != null) {
      maps = await db.query(
        'servers',
        where: 'folder_id = ?',
        whereArgs: [folderId],
      );
    } else {
      maps = await db.query('servers');
    }
    return List.generate(maps.length, (i) => Server.fromMap(maps[i]));
  }

  Future<void> createServer(Server server) async {
    final db = _dbService.db;
    await db.insert('servers', server.toMap());
  }

  Future<void> updateServer(Server server) async {
    final db = _dbService.db;
    await db.update(
      'servers',
      server.toMap(),
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }

  Future<void> deleteServer(String id) async {
    final db = _dbService.db;
    await db.delete('servers', where: 'id = ?', whereArgs: [id]);
  }

  // --- Credentials ---

  Future<List<Credential>> getCredentials() async {
    final db = _dbService.db;
    final List<Map<String, dynamic>> maps = await db.query('credentials');
    return List.generate(maps.length, (i) => Credential.fromMap(maps[i]));
  }

  Future<Credential?> getCredential(String id) async {
    final db = _dbService.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'credentials',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Credential.fromMap(maps.first);
    }
    return null;
  }

  Future<void> createCredential(Credential credential) async {
    final db = _dbService.db;
    await db.insert('credentials', credential.toMap());
  }

  Future<void> updateCredential(Credential credential) async {
    final db = _dbService.db;
    await db.update(
      'credentials',
      credential.toMap(),
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<void> deleteCredential(String id) async {
    final db = _dbService.db;
    await db.delete('credentials', where: 'id = ?', whereArgs: [id]);
  }
}
