import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/credential.dart';

class CreateCredentialDialog extends StatefulWidget {
  final Credential? credentialToEdit;
  final String? initialAuthType;

  const CreateCredentialDialog({
    super.key,
    this.credentialToEdit,
    this.initialAuthType,
  });

  @override
  State<CreateCredentialDialog> createState() => _CreateCredentialDialogState();
}

class _CreateCredentialDialogState extends State<CreateCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _secretPayloadController = TextEditingController();
  String _authType = 'password';

  @override
  void initState() {
    super.initState();
    if (widget.credentialToEdit != null) {
      _nameController.text = widget.credentialToEdit!.name;
      _usernameController.text = widget.credentialToEdit!.username;
      _authType = widget.credentialToEdit!.authType;
      _secretPayloadController.text = widget.credentialToEdit!.secretPayload;
    } else if (widget.initialAuthType != null) {
      _authType = widget.initialAuthType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _secretPayloadController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newCredential = Credential(
        id: widget.credentialToEdit?.id ?? Uuid().v4(),
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        authType: _authType,
        secretPayload: _secretPayloadController.text,
      );
      Navigator.of(context).pop(newCredential);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.credentialToEdit != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Credential' : 'Add Credential'),
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
                  labelText: 'Credential Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secretPayloadController,
                obscureText: _authType == 'password' || _authType == 'web_basic',
                maxLines: _authType == 'key' ? 5 : 1,
                decoration: InputDecoration(
                  labelText: _authType == 'key' ? 'Private Key (PEM)' : 'Password',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
