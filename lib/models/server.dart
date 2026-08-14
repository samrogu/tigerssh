class Server {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? folderId;
  final String? credentialId;

  Server({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.folderId,
    this.credentialId,
  });

  factory Server.fromMap(Map<String, dynamic> map) {
    return Server(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: map['port'] as int,
      folderId: map['folder_id'] as String?,
      credentialId: map['credential_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'folder_id': folderId,
      'credential_id': credentialId,
    };
  }
}
