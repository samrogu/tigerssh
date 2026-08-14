import 'package:flutter/material.dart';
import '../models/credential.dart';
import '../models/folder.dart';
import '../models/server.dart';
import '../repositories/vault_repository.dart';
import 'auth_manager.dart';

class VaultManager extends ChangeNotifier {
  final VaultRepository _repository;
  AuthManager? authManager;

  List<Folder> _folders = [];
  List<Server> _servers = [];
  List<Credential> _credentials = [];
  String? _selectedFolderId;
  bool _isLoading = false;

  VaultManager(this._repository);

  List<Folder> get folders => _folders;
  List<Server> get servers => _servers;
  List<Credential> get credentials => _credentials;
  String? get selectedFolderId => _selectedFolderId;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _folders = await _repository.getFolders();
      _servers = await _repository.getServers();
      _credentials = await _repository.getCredentials();
    } catch (e) {
      debugPrint('Error loading vault data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectFolder(String? folderId) {
    _selectedFolderId = folderId;
    loadData(); // Reload servers for the selected folder
  }

  Future<void> addFolder(Folder folder) async {
    await _repository.createFolder(folder);
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> deleteFolder(String id) async {
    await _repository.deleteFolder(id);
    if (_selectedFolderId == id) {
      _selectedFolderId = null;
    }
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> addServer(Server server) async {
    await _repository.createServer(server);
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> updateServer(Server server) async {
    await _repository.updateServer(server);
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> deleteServer(String id) async {
    await _repository.deleteServer(id);
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> addCredential(Credential credential) async {
    await _repository.createCredential(credential);
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> updateCredential(Credential credential) async {
    await _repository.updateCredential(credential);
    await loadData();
    await authManager?.syncVault();
  }

  Future<void> deleteCredential(String id) async {
    await _repository.deleteCredential(id);
    await loadData();
    await authManager?.syncVault();
  }
}
