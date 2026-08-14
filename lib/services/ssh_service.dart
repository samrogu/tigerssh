import 'dart:async';
import 'package:dartssh2/dartssh2.dart';

class SshService {
  SSHClient? _client;
  SSHSession? _session;

  bool get isConnected => _client != null && !_client!.isClosed;

  Future<SSHSession> connect({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKey,
  }) async {
    final socket = await SSHSocket.connect(host, port);
    
    _client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: () {
        if (password != null) return password;
        throw Exception('Password required but not provided');
      },
      identities: privateKey != null
          ? [
              ...SSHKeyPair.fromPem(privateKey)
            ]
          : [],
    );

    // Request a pty (pseudo-terminal) for the interactive shell
    _session = await _client!.shell(
      pty: const SSHPtyConfig(type: 'xterm-256color'),
    );

    return _session!;
  }

  void resizeTerminal(int width, int height) {
    if (_session != null) {
      _session!.resizeTerminal(width, height);
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
    _session = null;
  }
}
