import 'profile.dart';

typedef MessageType = String; // 'dm' | 'group'

class Message {
  final String id;
  final String senderId;
  final String? connectionId;
  final String? groupId;
  final String content;
  final MessageType type;
  final String createdAt;
  final Profile? sender;
  final bool isOptimistic;

  Message({
    required this.id,
    required this.senderId,
    this.connectionId,
    this.groupId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.sender,
    this.isOptimistic = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    Profile? senderProfile;
    if (json['sender'] != null && json['sender'] is Map<String, dynamic>) {
      senderProfile = Profile.fromJson(json['sender']);
    }

    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      connectionId: json['connection_id'] as String?,
      groupId: json['group_id'] as String?,
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'dm',
      createdAt: json['created_at'] as String? ?? '',
      sender: senderProfile,
    );
  }
}
