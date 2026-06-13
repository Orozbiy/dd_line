import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/supabase_client.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isSeller;
  final String? sellerId;

  const ChatListScreen({
    super.key,
    required this.isSeller,
    this.sellerId,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _service = ChatService();

  // ── Select режими (бир нече чатты тандап өчүрүү) ──
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String chatId) {
    setState(() {
      if (_selectedIds.contains(chatId)) {
        _selectedIds.remove(chatId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(chatId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAll(List<ChatModel> chats) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(chats.map((c) => c.id));
    });
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Чаттарды өчүрүү'),
        content:
            Text('${_selectedIds.length} чат өчүрүлөт. Улантасызбы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жок'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ооба, өчүрүү',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final chatId in _selectedIds) {
        await _service.deleteChat(chatId);
      }
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;

    if (myId == null) {
      return const Scaffold(
        body: Center(child: Text('Кирүү керек')),
      );
    }

    final stream = widget.isSeller
        ? _service.sellerChatsStream(widget.sellerId ?? myId)
        : _service.buyerChatsStream(myId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.black),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedIds.length} тандалды',
                  style: AppTextStyles.headingSmall),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title:
                  const Text('Билдирүүлөр', style: AppTextStyles.headingMedium),
            ),
      body: StreamBuilder<List<ChatModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('Чат жок', style: AppTextStyles.headingSmall),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Select режиминде "Баарын тандоо" ──
              if (_isSelectionMode)
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _selectAll(chats),
                      child: const Text('Баарын тандоо'),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: chats.length,
                  itemBuilder: (context, i) {
                    final chat = chats[i];
                    final unread = widget.isSeller
                        ? chat.sellerUnread
                        : chat.buyerUnread;
                    final hasProduct = !widget.isSeller &&
                        chat.productName != null &&
                        chat.productName!.isNotEmpty;
                    final isSelected = _selectedIds.contains(chat.id);

                    return GestureDetector(
                      onLongPress: () {
                        if (_isSelectionMode) return;
                        setState(() {
                          _isSelectionMode = true;
                          _selectedIds.add(chat.id);
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          isThreeLine: hasProduct,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          leading: _isSelectionMode
                              ? Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grey300,
                                  size: 28,
                                )
                              : _ChatAvatar(
                                  chat: chat,
                                  isSeller: widget.isSeller,
                                ),
                          title: widget.isSeller
                              ? _BuyerName(buyerId: chat.buyerId)
                              : Text(
                                  chat.sellerName,
                                  style: AppTextStyles.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasProduct) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (chat.productImage != null &&
                                        chat.productImage!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          chat.productImage!,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 24,
                                            height: 24,
                                            color: AppColors.grey100,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        chat.productName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                          color: AppColors.grey500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                chat.lastMessage.isNotEmpty
                                    ? chat.lastMessage
                                    : 'Жаңы чат',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.grey500),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(chat.formattedTime,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.grey400)),
                              if (unread > 0) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: _isSelectionMode
                              ? () => _toggleSelection(chat.id)
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen.fromChat(
                                          chat,
                                          isSeller: widget.isSeller),
                                    ),
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final ChatModel chat;
  final bool isSeller;

  const _ChatAvatar({required this.chat, required this.isSeller});

  @override
  Widget build(BuildContext context) {
    final otherUserId = isSeller ? chat.buyerId : chat.sellerId;

    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', otherUserId)
          .maybeSingle(),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data?['avatar_url'] as String?;
        final name = snapshot.data?['full_name'] as String? ?? '';

        return CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _BuyerName extends StatelessWidget {
  final String buyerId;

  const _BuyerName({required this.buyerId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('profiles')
          .select('full_name')
          .eq('id', buyerId)
          .maybeSingle(),
      builder: (context, snapshot) {
        final name = snapshot.data?['full_name'] as String? ?? 'Колдонуучу';
        return Text(
          name,
          style: AppTextStyles.labelLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
