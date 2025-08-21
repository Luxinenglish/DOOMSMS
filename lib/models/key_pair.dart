import 'dart:convert';

class KeyPair {
  final String publicKey;
  final String privateKey;
  final DateTime createdAt;
  final String fingerprint;

  KeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.createdAt,
    required this.fingerprint,
  });

  factory KeyPair.fromJson(Map<String, dynamic> json) => KeyPair(
        publicKey: json['publicKey'],
        privateKey: json['privateKey'],
        createdAt: DateTime.parse(json['createdAt']),
        fingerprint: json['fingerprint'],
      );

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'privateKey': privateKey,
        'createdAt': createdAt.toIso8601String(),
        'fingerprint': fingerprint,
      };
}