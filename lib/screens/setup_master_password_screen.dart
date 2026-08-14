import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../managers/auth_manager.dart';

class SetupMasterPasswordScreen extends StatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  State<SetupMasterPasswordScreen> createState() => _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState extends State<SetupMasterPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  String? _selectedPath;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _pickStoragePath() async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Select Vault Location',
      fileName: 'mi_boveda.cvault',
      allowedExtensions: ['cvault'],
      type: FileType.custom,
    );
    if (outputFile != null) {
      if (!outputFile.endsWith('.cvault')) {
        outputFile = '$outputFile.cvault';
      }
      setState(() {
        _selectedPath = outputFile;
      });
    }
  }

  Future<void> _openExistingVault() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      dialogTitle: 'Open Existing Vault',
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final selectedFile = result.files.single.path!;
      
      try {
        await context.read<AuthManager>().switchDatabase(selectedFile);
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = "Error opening vault: $e";
          });
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_selectedPath != null) {
        // Just set the path in SharedPreferences before unlocking
        await context.read<AuthManager>().setDatabasePath(_selectedPath!);
      }
      await context.read<AuthManager>().setupMasterPassword(_passwordController.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Master Password')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWide ? 900 : 400),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Branding and Information
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset('Icono.png', width: 160, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome to your Secure Vault',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please create a strong Master Password. This password will be used to encrypt your database locally. We do not store this password, so if you lose it, your data cannot be recovered.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        // Right Column: Form Fields
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildFormFields(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ClipOval(
            child: Image.asset('Icono.png', width: 128, height: 128, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome to your Secure Vault',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Please create a strong Master Password. This password will be used to encrypt your database locally. We do not store this password, so if you lose it, your data cannot be recovered.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ..._buildFormFields(),
      ],
    );
  }
  
  List<Widget> _buildFormFields() {
    return [
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Master Password',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Confirm Master Password',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ],
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: _pickStoragePath,
        icon: const Icon(Icons.folder_open),
        label: Text(_selectedPath != null ? _selectedPath! : 'Select Storage Location (Optional)'),
      ),
      if (_selectedPath == null)
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'If not selected, the vault will be saved in the default app directory.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Initialize Vault'),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _openExistingVault,
        child: const Text('Open an existing Vault...'),
      ),
    ];
  }
}
