import 'dart:convert';

enum MessageStatus { sending, sent, delivered, read, failed }
enum MessageType { text, image, file }

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final String encryptedContent;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isEncrypted;

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.encryptedContent,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.isEncrypted = true,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        senderId: json['senderId'],
        recipientId: json['recipientId'],
        content: json['content'],
        encryptedContent: json['encryptedContent'],
        type: MessageType.values[json['type']],
        status: MessageStatus.values[json['status']],
        timestamp: DateTime.parse(json['timestamp']),
        isEncrypted: json['isEncrypted'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'recipientId': recipientId,
        'content': content,
        'encryptedContent': encryptedContent,
        'type': type.index,
        'status': status.index,
        'timestamp': timestamp.toIso8601String(),
        'isEncrypted': isEncrypted,
      };

  Message copyWith({
    MessageStatus? status,
    String? content,
    String? encryptedContent,
  }) =>
      Message(
        id: id,
        senderId: senderId,
        recipientId: recipientId,
        content: content ?? this.content,
        encryptedContent: encryptedContent ?? this.encryptedContent,
        type: type,
        status: status ?? this.status,
        timestamp: timestamp,
        isEncrypted: isEncrypted,
      );
}