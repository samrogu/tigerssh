import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/folder.dart';
import '../models/server.dart';
import '../models/credential.dart';

class CreateServerDialog extends StatefulWidget {
  final List<Folder> folders;
  final List<Credential> credentials;
  final String? initialFolderId;
  final Server? serverToEdit;

  const CreateServerDialog({
    super.key,
    required this.folders,
    required this.credentials,
    this.initialFolderId,
    this.serverToEdit,
  });

  @override
  State<CreateServerDialog> createState() => _CreateServerDialogState();
}

class _CreateServerDialogState extends State<CreateServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  String? _selectedFolderId;
  String? _selectedCredentialId;

  @override
  void initState() {
    super.initState();
    if (widget.serverToEdit != null) {
      _nameController.text = widget.serverToEdit!.name;
      _hostController.text = widget.serverToEdit!.host;
      _portController.text = widget.serverToEdit!.port.toString();
      _selectedFolderId = widget.serverToEdit!.folderId;
      _selectedCredentialId = widget.serverToEdit!.credentialId;
    } else {
      _selectedFolderId = widget.initialFolderId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newServer = Server(
        id: widget.serverToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        folderId: _selectedFolderId,
        credentialId: _selectedCredentialId,
      );
      Navigator.of(context).pop(newServer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.serverToEdit == null ? 'Add Server' : 'Edit Server'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host (IP or Domain)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (int.tryParse(value.trim()) == null) return 'Invalid port';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedFolderId,
                decoration: const InputDecoration(
                  labelText: 'Folder',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None (Root)'),
                  ),
                  ...widget.folders.map((f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.name),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedFolderId = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedCredentialId,
                decoration: const InputDecoration(
                  labelText: 'Credential (Optional for now)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ...widget.credentials
                      .where((c) => c.authType == 'password' || c.authType == 'key')
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} (${c.username})'),
                          )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCredentialId = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.serverToEdit == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
