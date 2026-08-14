import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../managers/terminal_session_manager.dart';

class TerminalTab extends StatelessWidget {
  final TerminalSession session;

  const TerminalTab({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    if (session.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Connection Failed:\n${session.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                session.connect();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!session.isConnected) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black, // Dark background
      child: TerminalView(
        session.terminal,
        textStyle: const TerminalStyle(
          fontSize: 14,
          fontFamily: 'Courier',
        ),
        theme: TerminalThemes.defaultTheme,
      ),
    );
  }
}
