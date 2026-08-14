import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'managers/auth_manager.dart';
import 'managers/vault_manager.dart';
import 'managers/terminal_session_manager.dart';
import 'repositories/vault_repository.dart';
import 'services/database_service.dart';
import 'screens/setup_master_password_screen.dart';
import 'screens/unlock_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseService = EncryptedDatabaseService();
  final vaultRepository = VaultRepository(databaseService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthManager(databaseService)),
        ChangeNotifierProxyProvider<AuthManager, VaultManager>(
          create: (_) => VaultManager(vaultRepository),
          update: (_, authManager, vaultManager) {
            vaultManager!.authManager = authManager;
            return vaultManager;
          },
        ),
        ChangeNotifierProvider(create: (_) => TerminalSessionManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TigerSSH',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, authManager, child) {
        switch (authManager.state) {
          case AuthState.initial:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthState.setupRequired:
            return const SetupMasterPasswordScreen();
          case AuthState.locked:
            return const UnlockScreen();
          case AuthState.unlocked:
            // Wrap the main app area in a Listener to detect user activity
            return Listener(
              onPointerDown: (_) => authManager.userActivityDetected(),
              onPointerMove: (_) => authManager.userActivityDetected(),
              onPointerUp: (_) => authManager.userActivityDetected(),
              behavior: HitTestBehavior.translucent,
              child: const Scaffold(
                body: DashboardScreen(),
              ),
            );
          case AuthState.error:
            return const Scaffold(body: Center(child: Text('An error occurred')));
        }
      },
    );
  }
}
