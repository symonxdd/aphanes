/// A paired webOS TV. The private key lives in secure storage alongside
/// this record (see `DeviceStorageService`), never in plaintext prefs.
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.model,
    required this.host,
    required this.port,
    required this.username,
    required this.privateKeyPem,
    required this.pairedAt,
    this.passphrase,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      model: json['model'] as String?,
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      privateKeyPem: json['privateKeyPem'] as String,
      pairedAt: DateTime.parse(json['pairedAt'] as String),
      passphrase: json['passphrase'] as String?,
    );
  }

  final String id;
  final String name;
  final String? model;
  final String host;
  final int port;
  final String username;
  final String privateKeyPem;
  final DateTime pairedAt;

  /// The passphrase typed at pairing time. The app has no use for it
  /// after pairing (it only unlocked the key once) and keeps it solely so
  /// the device detail page can show it. Null for a TV paired before the
  /// app started keeping it.
  final String? passphrase;

  Device copyWith({String? name, String? host}) {
    return Device(
      id: id,
      name: name ?? this.name,
      model: model,
      host: host ?? this.host,
      port: port,
      username: username,
      privateKeyPem: privateKeyPem,
      pairedAt: pairedAt,
      passphrase: passphrase,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'model': model,
    'host': host,
    'port': port,
    'username': username,
    'privateKeyPem': privateKeyPem,
    'pairedAt': pairedAt.toIso8601String(),
    'passphrase': passphrase,
  };
}
