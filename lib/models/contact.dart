import 'dart:convert';

class Contact {
  final String id;
  final String name;
  final String publicKey;
  final String? avatar;
  final DateTime lastSeen;
  final bool isOnline;
  final bool isVerified;

  Contact({
    required this.id,
    required this.name,
    required this.publicKey,
    this.avatar,
    required this.lastSeen,
    this.isOnline = false,
    this.isVerified = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'],
        name: json['name'],
        publicKey: json['publicKey'],
        avatar: json['avatar'],
        lastSeen: DateTime.parse(json['lastSeen']),
        isOnline: json['isOnline'] ?? false,
        isVerified: json['isVerified'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'publicKey': publicKey,
        'avatar': avatar,
        'lastSeen': lastSeen.toIso8601String(),
        'isOnline': isOnline,
        'isVerified': isVerified,
      };

  Contact copyWith({
    String? name,
    String? publicKey,
    String? avatar,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isVerified,
  }) =>
      Contact(
        id: id,
        name: name ?? this.name,
        publicKey: publicKey ?? this.publicKey,
        avatar: avatar ?? this.avatar,
        lastSeen: lastSeen ?? this.lastSeen,
        isOnline: isOnline ?? this.isOnline,
        isVerified: isVerified ?? this.isVerified,
      );
}