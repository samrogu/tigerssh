import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/vault_package_service.dart';

enum AuthState {
  initial,
  setupRequired,
  locked,
  unlocked,
  error
}

class AuthManager extends ChangeNotifier {
  final EncryptedDatabaseService _databaseService;
  VaultPackageService? _packageService;
  
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  Timer? _inactivityTimer;
  String? _activeVaultPath;
  String? _currentPassword; // Store password in memory while unlocked for syncing
  
  // As requested, default inactivity timeout is 5 minutes
  static const Duration _timeoutDuration = Duration(minutes: 5);
  
  AuthManager(this._databaseService) {
    _initPackageService().then((_) => _checkInitialState());
  }

  Future<void> _initPackageService() async {
    final dbPath = await _databaseService.dbPath;
    final saltPath = await _databaseService.saltPath;
    _packageService = VaultPackageService(
      internalDbPath: dbPath,
      internalSaltPath: saltPath,
    );
    
    final prefs = await SharedPreferences.getInstance();
    _activeVaultPath = prefs.getString('active_cvault_path');
    
    // Security: Clean up any stale unpacked files from previous crashed sessions
    await _cleanupTempFiles();
  }

  Future<void> _cleanupTempFiles() async {
    final dbFile = File(await _databaseService.dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    final saltFile = File(await _databaseService.saltPath);
    if (await saltFile.exists()) {
      await saltFile.delete();
    }
  }
  
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  
  Future<void> _checkInitialState() async {
    if (_activeVaultPath != null && await File(_activeVaultPath!).exists()) {
      _state = AuthState.locked;
    } else {
      _state = AuthState.setupRequired;
    }
    notifyListeners();
  }

  Future<void> switchDatabase(String newPath) async {
    _state = AuthState.initial;
    notifyListeners();
    
    await _databaseService.closeDatabase();
    await _cleanupTempFiles();
    _currentPassword = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_cvault_path', newPath);
    _activeVaultPath = newPath;
    
    await _checkInitialState();
  }
  
  Future<void> setDatabasePath(String newPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_cvault_path', newPath);
    _activeVaultPath = newPath;
  }
  
  Future<void> syncVault() async {
    if (_activeVaultPath != null && _packageService != null && _currentPassword != null) {
      try {
        await _packageService!.packVault(_activeVaultPath!, _currentPassword!);
      } catch (e) {
        debugPrint("Error syncing vault: $e");
      }
    }
  }

  Future<void> exportVault(String exportPath) async {
    if (_packageService != null && _currentPassword != null) {
      await _packageService!.packVault(exportPath, _currentPassword!);
    } else {
      throw Exception("Cannot export: vault is not unlocked.");
    }
  }
  
  Future<void> setupMasterPassword(String password) async {
    _state = AuthState.initial;
    notifyListeners();
    try {
      final success = await _databaseService.unlockDatabase(password);
      if (success) {
        _currentPassword = password;
        _state = AuthState.unlocked;
        await syncVault(); // Package and encrypt the newly generated salt and db
        _resetTimer();
      } else {
        _state = AuthState.setupRequired;
        _errorMessage = "Failed to setup database.";
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _state = AuthState.setupRequired;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }
  
  Future<void> unlock(String password) async {
    _errorMessage = null;
    notifyListeners(); 
    
    try {
      if (_activeVaultPath == null) throw Exception("No vault selected");
      
      // 1. Decrypt and unpack the vault to temp files
      await _packageService!.unpackVault(_activeVaultPath!, password);
      
      // 2. Open the unpacked database
      final success = await _databaseService.unlockDatabase(password);
      if (success) {
        _currentPassword = password;
        _state = AuthState.unlocked;
        _resetTimer();
      } else {
        _errorMessage = "Failed to open database.";
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }
  
  Future<void> lock() async {
    _inactivityTimer?.cancel();
    
    // Ensure data is saved and encrypted before locking
    if (_state == AuthState.unlocked) {
      await syncVault();
    }
    
    await _databaseService.closeDatabase();
    await _cleanupTempFiles(); // Delete plaintext temp files!
    
    _currentPassword = null;
    _state = AuthState.locked;
    notifyListeners();
  }
  
  Future<void> createNewVault() async {
    _state = AuthState.initial;
    notifyListeners();
    
    await _databaseService.closeDatabase();
    await _cleanupTempFiles();
    _currentPassword = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_cvault_path');
    _activeVaultPath = null;
    
    await _checkInitialState();
  }
  
  void userActivityDetected() {
    if (_state == AuthState.unlocked) {
      _resetTimer();
    }
  }
  
  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () {
      lock();
    });
  }
  
  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _currentPassword = null;
    super.dispose();
  }
}
