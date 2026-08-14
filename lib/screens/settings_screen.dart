import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/vault_package_service.dart';
import '../managers/auth_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final prefs = await SharedPreferences.getInstance();
    final activeCvaultPath = prefs.getString('active_cvault_path');
    
    final dbService = EncryptedDatabaseService();
    final actualPath = await dbService.dbPath;
    
    setState(() {
      _currentPath = activeCvaultPath ?? actualPath;
    });
  }

  Future<void> _saveAs() async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Export Database As...',
      fileName: 'mi_boveda.cvault',
      allowedExtensions: ['cvault'],
      type: FileType.custom,
    );

    if (outputFile != null) {
      if (!outputFile.endsWith('.cvault')) {
        outputFile = '$outputFile.cvault';
      }

      try {
        await context.read<AuthManager>().exportVault(outputFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database exported successfully as .cvault! This is a backup copy.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to export vault: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openDatabase() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      dialogTitle: 'Import Existing Database',
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final selectedFile = result.files.single.path!;
      
      await context.read<AuthManager>().switchDatabase(selectedFile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database imported and activated!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Text(
            'Database Storage Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a custom folder (like Dropbox, Google Drive or iCloud) to store your encrypted vault. '
            'The entire vault will be packaged into a single secure .cvault file.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentPath ?? 'Loading...',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openDatabase,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Import (Open)'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveAs,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export (Save As)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
