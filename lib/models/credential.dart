class Credential {
  final String id;
  final String name;
  final String username;
  final String authType; // 'password' or 'key'
  final String secretPayload;

  Credential({
    required this.id,
    required this.name,
    required this.username,
    required this.authType,
    required this.secretPayload,
  });

  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String,
      authType: map['auth_type'] as String,
      secretPayload: map['secret_payload'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'auth_type': authType,
      'secret_payload': secretPayload,
    };
  }
}
