import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/supabase_client.dart';
import '../../../core/utils/image_utils.dart';
import '../../../services/notification_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_record_button.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String sellerName;
  final String productName;
  final String productImage;
  final bool isSeller;
  final String buyerId;
  final String sellerId;
  final String otherAvatarUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.sellerName,
    required this.productName,
    required this.productImage,
    required this.isSeller,
    required this.buyerId,
    required this.sellerId,
    this.otherAvatarUrl = '',
  });

  factory ChatScreen.fromChat(ChatModel chat, {required bool isSeller}) {
    return ChatScreen(
      chatId: chat.id,
      sellerName: chat.sellerName,
      productName: chat.productName ?? '',
      productImage: chat.productImage ?? '',
      isSeller: isSeller,
      buyerId: chat.buyerId,
      sellerId: chat.sellerId,
      otherAvatarUrl: isSeller ? chat.buyerAvatar : chat.sellerAvatar,
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _cloudName = 'dedwm4krp';
  static const _uploadPreset = 'dd-online';

  final _service = ChatService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSendingImage = false;
  bool _hasText = false;

  StreamSubscription<List<MessageModel>>? _msgSub;

  // ── Select режими (бир нече билдирүү тандап өчүрүү) ──
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // ── Жооп берүү режими (2-этап) ──
  MessageModel? _replyingTo;

  String? get _myId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _markRead();
    _listenAndMarkRead();
    _msgCtrl.addListener(() {
      final has = _msgCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _msgSub?.cancel();
    super.dispose();
  }

  Future<void> _markRead() async {
    final myId = _myId;
    if (myId == null) return;
    await _service.markAsRead(
      chatId: widget.chatId,
      myUserId: myId,
      readerIsBuyer: !widget.isSeller,
    );
  }

  // ── Чат ачык турганда экинчи тараптан жаны билдирүү
  // келсе, аны дароо "окулду" деп белгилейт. Натыйжада
  // жөнөткөн тараптын экранында галочка дароо көк болуп
  // (done_all_rounded) өзгөрөт. ──
  void _listenAndMarkRead() {
    _msgSub = _service.messagesStream(widget.chatId).listen((messages) {
      final myId = _myId;
      if (myId == null || messages.isEmpty) return;
      final hasUnread = messages.any(
        (m) => m.senderId != myId && !m.isRead,
      );
      if (hasUnread) {
        _markRead();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ── Экинчи тараптын ID'син жана атын аныктоо (push үчүн) ──
  String get _receiverUid => widget.isSeller ? widget.buyerId : widget.sellerId;

  String get _senderDisplayName =>
      widget.isSeller ? 'Сатуучу' : widget.sellerName;

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    final myId = _myId;
    if (text.isEmpty || myId == null) return;

    _msgCtrl.clear();
    final replyTo = _replyingTo;
    if (replyTo != null) {
      setState(() => _replyingTo = null);
    }

    await _service.sendMessage(
      chatId: widget.chatId,
      senderId: myId,
      text: text,
      replyToId: replyTo?.id,
      replyToText: replyTo != null
          ? (replyTo.text.isNotEmpty ? replyTo.text : '📷 Сүрөт')
          : null,
    );

    NotificationService().sendChatNotification(
      receiverUid: _receiverUid,
      senderName: _senderDisplayName,
      messageText: text,
      chatId: widget.chatId,
    );

    _scrollToBottom();
  }

  // ── Сүрөт булагын тандоо (камера/галерея) ──
  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Камера', style: AppTextStyles.labelLarge),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_outlined, color: AppColors.primary),
              title: const Text('Галерея', style: AppTextStyles.labelLarge),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Сүрөт тандоо жана жөнөтүү ──
  Future<void> _pickAndSendImage() async {
    final myId = _myId;
    if (myId == null) return;

    final source = await _chooseImageSource();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isSendingImage = true);

    try {
      final bytes = await picked.readAsBytes();
      final compressed = await compressImage(bytes);
      final url = await _uploadToCloudinary(compressed);

      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сүрөт жүктөлбөдү')),
          );
        }
        return;
      }

      final replyTo = _replyingTo;
      if (replyTo != null) {
        setState(() => _replyingTo = null);
      }

      await _service.sendMessage(
        chatId: widget.chatId,
        senderId: myId,
        imageUrl: url,
        replyToId: replyTo?.id,
        replyToText: replyTo != null
            ? (replyTo.text.isNotEmpty ? replyTo.text : '📷 Сүрөт')
            : null,
      );

      NotificationService().sendChatNotification(
        receiverUid: _receiverUid,
        senderName: _senderDisplayName,
        messageText: '📷 Сүрөт',
        chatId: widget.chatId,
      );

      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  Future<String?> _uploadToCloudinary(Uint8List bytes) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════
  // ҮН БИЛДИРҮҮ (3-этап)
  // ══════════════════════════════════════════════

  Future<String?> _uploadAudioToCloudinary(String filePath) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendVoiceMessage(String path, int durationSeconds) async {
    final myId = _myId;
    if (myId == null) return;

    setState(() => _isSendingImage = true);

    try {
      final url = await _uploadAudioToCloudinary(path);

      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Үн билдирүү жүктөлбөдү')),
          );
        }
        return;
      }

      final replyTo = _replyingTo;
      if (replyTo != null) {
        setState(() => _replyingTo = null);
      }

      await _service.sendMessage(
        chatId: widget.chatId,
        senderId: myId,
        audioUrl: url,
        audioDuration: durationSeconds,
        replyToId: replyTo?.id,
        replyToText: replyTo != null
            ? (replyTo.text.isNotEmpty ? replyTo.text : '📷 Сүрөт')
            : null,
      );

      NotificationService().sendChatNotification(
        receiverUid: _receiverUid,
        senderName: _senderDisplayName,
        messageText: '🎤 Үн билдирүү',
        chatId: widget.chatId,
      );

      _scrollToBottom();
    } finally {
      // ── Убактылуу файлды тазалоо ──
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}

      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  // ══════════════════════════════════════════════
  // SELECT РЕЖИМИ
  // ══════════════════════════════════════════════

  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(messageId);
    });
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedIds.contains(messageId)) {
        _selectedIds.remove(messageId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(messageId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAll(List<MessageModel> messages) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(messages.map((m) => m.id));
    });
  }

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Билдирүүлөрдү өчүрүү'),
        content: Text(
            '${_selectedIds.length} билдирүү өчүрүлөт. Улантасызбы?'),
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
      await _service.deleteMessages(_selectedIds.toList());
      _exitSelectionMode();
    }
  }

  // ══════════════════════════════════════════════
  // LONG-PRESS MENU АРАКЕТТЕРИ (2-этап)
  // ══════════════════════════════════════════════

  void _copyMessage(MessageModel msg) {
    if (msg.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: msg.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Көчүрүлдү'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteSingle(MessageModel msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Билдирүүнү өчүрүү'),
        content: const Text('Бул билдирүү өчүрүлөт. Улантасызбы?'),
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
      await _service.deleteMessages([msg.id]);
    }
  }

  void _startReply(MessageModel msg) {
    setState(() => _replyingTo = msg);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  // ── Reply preview'ге басканда, шилтеме болгон билдирүүгө скролл кылуу ──
  void _scrollToMessage(String? replyToId, List<MessageModel> messages) {
    if (replyToId == null) return;
    final reversedIndex =
        messages.indexWhere((m) => m.id == replyToId);
    if (reversedIndex == -1) return;
    final listIndex = messages.length - 1 - reversedIndex;
    final offset = listIndex * 80.0;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final myId = _myId;

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
                  onPressed:
                      _selectedIds.isEmpty ? null : _deleteSelected,
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  if (widget.isSeller) ...[
                    _OtherUserAvatar(avatarUrl: widget.otherAvatarUrl),
                    const SizedBox(width: 10),
                  ] else if (widget.productImage.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.productImage,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 36,
                          height: 36,
                          color: AppColors.grey100,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isSeller ? 'Кардар' : widget.sellerName,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.productName.isNotEmpty)
                          Text(
                            widget.productName,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.grey500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: myId == null
                ? const Center(child: Text('Кирүү керек'))
                : StreamBuilder<List<MessageModel>>(
                    stream: _service.messagesStream(widget.chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Text('Билдирүү жок, жазып баштаңыз',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.grey400)),
                        );
                      }

                      return Column(
                        children: [
                          // ── Select режиминде "Баарын тандоо" ──
                          if (_isSelectionMode)
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _selectAll(messages),
                                  child: const Text('Баарын тандоо'),
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              reverse: true,
                              padding: const EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, i) {
                                final msg = messages[messages.length - 1 - i];
                                final isMe = msg.senderId == myId;
                                return MessageBubble(
                                  message: msg,
                                  isMe: isMe,
                                  isSelectionMode: _isSelectionMode,
                                  isSelected: _selectedIds.contains(msg.id),
                                  onLongPress: () =>
                                      _enterSelectionMode(msg.id),
                                  onTap: () => _toggleSelection(msg.id),
                                  onCopy: () => _copyMessage(msg),
                                  onDelete: () => _deleteSingle(msg),
                                  onReply: () => _startReply(msg),
                                  onReplyTap: () =>
                                      _scrollToMessage(msg.replyToId, messages),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // ── Жооп берүү preview'у (input үстүндө) ──
          if (!_isSelectionMode && _replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Жооп',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primary),
                        ),
                        Text(
                          _replyingTo!.text.isNotEmpty
                              ? _replyingTo!.text
                              : '📷 Сүрөт',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close,
                        color: AppColors.grey400, size: 20),
                  ),
                ],
              ),
            ),
          // ── Билдирүү жазуу талаасы (select режиминде жашырылат) ──
          if (!_isSelectionMode)
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Сүрөт жөнөтүү баскычы ──
                  _isSendingImage
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _pickAndSendImage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.grey500,
                              size: 22,
                            ),
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Билдирүү жазыңыз...',
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── Текст бар болсо send, жок болсо микрофон ──
                  _hasText
                      ? GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                          ),
                        )
                      : VoiceRecordButton(
                          onRecorded: _sendVoiceMessage,
                          onCancel: () {},
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Башка колдонуучунун (кардардын) аватары. Аватар жок болсо
// нейтралдуу icon-айлана көрсөтүлөт. ──
class _OtherUserAvatar extends StatelessWidget {
  final String avatarUrl;

  const _OtherUserAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.grey100,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? const Icon(Icons.person, size: 20, color: AppColors.grey400)
          : null,
    );
  }
}