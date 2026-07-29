class Conversation {
  final String id;
  final String type; // 'dm' | 'group'
  final String name;
  final String? connectionId;
  final String? groupId;
  final String? partnerId;
  final String? partnerAvatar;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    this.connectionId,
    this.groupId,
    this.partnerId,
    this.partnerAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'dm',
      name: json['name'] as String? ?? '',
      connectionId: json['connectionId'] as String?,
      groupId: json['groupId'] as String?,
      partnerId: json['partnerId'] as String?,
      partnerAvatar: json['partnerAvatar'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
