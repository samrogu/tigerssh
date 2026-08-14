class Folder {
  final String id;
  final String name;
  final String? parentFolderId;
  final String? defaultCredentialId;

  Folder({
    required this.id,
    required this.name,
    this.parentFolderId,
    this.defaultCredentialId,
  });

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      parentFolderId: map['parent_folder_id'] as String?,
      defaultCredentialId: map['default_credential_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_folder_id': parentFolderId,
      'default_credential_id': defaultCredentialId,
    };
  }
}
