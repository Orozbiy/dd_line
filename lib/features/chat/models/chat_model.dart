class ChatModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final String buyerId;
  final String buyerAvatar;
  final String? productId;
  final String? productName;
  final String? productImage;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;
  final int sellerUnread;
  final int buyerUnread;
  final bool isOnline;
  final String lastSeen;

  ChatModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerAvatar,
    required this.buyerId,
    this.buyerAvatar = '',
    this.productId,
    this.productName,
    this.productImage,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.sellerUnread = 0,
    this.buyerUnread = 0,
    this.isOnline = false,
    this.lastSeen = '',
  });

  /// Supabase'тин `chats` таблицасынан (snake_case) моделди жасоо.
  ///
  /// `data` JOIN аркылуу `products(title, images)` камтышы мүмкүн.
  /// `isSeller` — учурдагы колдонуучу сатуучубу (unread санын тандоо үчүн).
  factory ChatModel.fromMap(Map<String, dynamic> data,
      {required bool isSeller}) {
    final productData = data['products'] as Map<String, dynamic>?;
    final images = productData?['images'] as List?;

    final sellerUnread = data['seller_unread'] as int? ?? 0;
    final buyerUnread = data['buyer_unread'] as int? ?? 0;

    return ChatModel(
      id: data['id'] as String? ?? '',
      sellerId: data['seller_id'] as String? ?? '',
      sellerName: data['seller_name'] as String? ?? '',
      sellerAvatar: data['seller_avatar'] as String? ?? '',
      buyerId: data['buyer_id'] as String? ?? '',
      buyerAvatar: data['buyer_avatar'] as String? ?? '',
      productId: data['product_id'] as String?,
      productName:
          productData?['title'] as String? ?? data['product_name'] as String?,
      productImage: (images != null && images.isNotEmpty)
          ? images.first as String
          : data['product_image'] as String?,
      lastMessage: data['last_message'] as String? ?? '',
      lastTime: data['last_message_at'] != null
          ? DateTime.parse(data['last_message_at'] as String)
          : DateTime.now(),
      unreadCount: isSeller ? sellerUnread : buyerUnread,
      sellerUnread: sellerUnread,
      buyerUnread: buyerUnread,
      isOnline: false,
      lastSeen: '',
    );
  }

  String get formattedTime {
    final diff = DateTime.now().difference(lastTime);
    if (diff.inMinutes < 1) return 'Азыр';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} саат';
    return '${diff.inDays} күн';
  }
}
