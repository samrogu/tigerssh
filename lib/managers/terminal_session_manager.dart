import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../models/server.dart';
import '../models/credential.dart';
import '../services/ssh_service.dart';

class TerminalSession {
  final String id;
  final Server server;
  final Credential? credential;
  final Terminal terminal;
  final SshService sshService;
  
  bool isConnected = false;
  String? error;
  Timer? _inactivityTimer;
  final VoidCallback onActivity;
  final VoidCallback onDisconnect;

  TerminalSession({
    required this.id,
    required this.server,
    this.credential,
    required this.onActivity,
    required this.onDisconnect,
  })  : terminal = Terminal(),
        sshService = SshService();

  Future<void> connect() async {
    if (credential == null) {
      error = 'No credentials provided for this server.';
      return;
    }

    try {
      final session = await sshService.connect(
        host: server.host,
        port: server.port,
        username: credential!.username,
        password: credential!.authType == 'password'
            ? credential!.secretPayload
            : null,
        privateKey: credential!.authType == 'key'
            ? credential!.secretPayload
            : null,
      );

      session.stdout.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });
      session.stderr.listen((data) {
        terminal.write(String.fromCharCodes(data));
      });

      terminal.onOutput = (data) {
        onActivity(); // Reset timer on user input
        session.stdin.add(Uint8List.fromList(data.codeUnits));
      };

      terminal.onResize = (w, h, pw, ph) {
        sshService.resizeTerminal(w, h);
      };

      isConnected = true;
      error = null;
      _startTimer();
    } catch (e) {
      error = e.toString();
      isConnected = false;
    }
  }

  void _startTimer() {
    _inactivityTimer?.cancel();
    // 5 minute timeout by default
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      disconnect();
      onDisconnect();
    });
  }

  void resetTimer() {
    if (isConnected) {
      _startTimer();
    }
  }

  void disconnect() {
    _inactivityTimer?.cancel();
    sshService.disconnect();
    isConnected = false;
  }
}

class TerminalSessionManager extends ChangeNotifier {
  final List<TerminalSession> _sessions = [];
  int _activeTabIndex = 0;

  List<TerminalSession> get sessions => _sessions;
  int get activeTabIndex => _activeTabIndex;

  void openSession(Server server, Credential? credential) {
    // Check if session already exists for this server (optional, could allow multiple)
    // We will allow multiple for now, or just focus it if it exists.
    final existingIndex = _sessions.indexWhere((s) => s.server.id == server.id);
    if (existingIndex != -1) {
      _activeTabIndex = existingIndex;
      notifyListeners();
      return;
    }

    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final session = TerminalSession(
      id: newSessionId,
      server: server,
      credential: credential,
      onActivity: () {
        // Reset timer internally handled by session
      },
      onDisconnect: () {
        // Handle auto-disconnect
        notifyListeners();
      },
    );

    _sessions.add(session);
    _activeTabIndex = _sessions.length - 1;
    notifyListeners();

    session.connect().then((_) {
      notifyListeners();
    });
  }

  void closeSession(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index].disconnect();
      _sessions.removeAt(index);
      
      // Adjust active tab
      if (_sessions.isEmpty) {
        _activeTabIndex = 0;
      } else if (_activeTabIndex >= _sessions.length) {
        _activeTabIndex = _sessions.length - 1;
      }
      notifyListeners();
    }
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void registerActivity() {
    if (_sessions.isNotEmpty && _activeTabIndex < _sessions.length) {
      _sessions[_activeTabIndex].resetTimer();
    }
  }
  
  void disconnectAll() {
    for (var session in _sessions) {
      session.disconnect();
    }
    _sessions.clear();
    _activeTabIndex = 0;
    notifyListeners();
  }
}
