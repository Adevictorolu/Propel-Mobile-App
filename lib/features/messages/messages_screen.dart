import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/presence_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  List<Conversation> _conversations = [];
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final role = authProvider.role;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final convs = await FirebaseService.fetchConversations(user.uid, role);
      setState(() {
        _conversations = convs;
        if (convs.isNotEmpty) {
          _selectedConversation = convs.first;
        }
      });
    } catch (e) {
      print('[MessagesScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (_isLoading) {
      return const Scaffold(body: Center(child: ShimmerLoading(width: 400, height: 300)));
    }

    if (_conversations.isEmpty) {
      return const Scaffold(
        body: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.slate400),
                SizedBox(height: 12),
                Text('No conversations yet', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Active connections will appear here for messaging.', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 320,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.slate200)),
              ),
              child: _buildConversationList(),
            ),
            Expanded(
              child: _selectedConversation != null
                  ? _ChatDetailPanel(conversation: _selectedConversation!)
                  : const Center(child: Text('Select a conversation')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _selectedConversation != null
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedConversation = null),
              ),
              title: Text(_selectedConversation!.name),
            )
          : AppBar(title: const Text('Messages')),
      body: _selectedConversation != null
          ? _ChatDetailPanel(conversation: _selectedConversation!)
          : _buildConversationList(),
    );
  }

  Widget _buildConversationList() {
    final presenceProvider = context.watch<PresenceProvider>();

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = _conversations[index];
        final isSelected = c.id == _selectedConversation?.id;
        final isOnline = c.partnerId != null && presenceProvider.isOnline(c.partnerId!);

        return ListTile(
          selected: isSelected,
          selectedTileColor: AppColors.brandBlue50,
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandBlue600,
                backgroundImage: c.partnerAvatar != null ? NetworkImage(c.partnerAvatar!) : null,
                child: c.partnerAvatar == null ? Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            c.lastMessage ?? 'Tap to start conversation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          onTap: () => setState(() => _selectedConversation = c),
        );
      },
    );
  }
}

class _ChatDetailPanel extends StatefulWidget {
  final Conversation conversation;

  const _ChatDetailPanel({required this.conversation});

  @override
  State<_ChatDetailPanel> createState() => _ChatDetailPanelState();
}

class _ChatDetailPanelState extends State<_ChatDetailPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final channelId = widget.conversation.connectionId ?? widget.conversation.groupId ?? '';
      final currentUserId = context.read<AuthProvider>().user?.uid;
      context.read<ChatProvider>().initChannel(
            type: widget.conversation.type,
            channelId: channelId,
            userId: currentUserId,
          );
    });
  }

  @override
  void didUpdateWidget(covariant _ChatDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      final channelId = widget.conversation.connectionId ?? widget.conversation.groupId ?? '';
      final currentUserId = context.read<AuthProvider>().user?.uid;
      context.read<ChatProvider>().initChannel(
            type: widget.conversation.type,
            channelId: channelId,
            userId: currentUserId,
          );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandBlue600,
                child: Text(widget.conversation.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.conversation.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(widget.conversation.type.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: chatProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProvider.messages[index];
                    final isMe = msg.senderId == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.brandGreen600
                              : (isDark ? AppColors.slate700 : AppColors.slate200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.slate800),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatTimeAgo(msg.createdAt),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : AppColors.slate500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(backgroundColor: AppColors.brandGreen600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
