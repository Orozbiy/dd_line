import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// ─────────────────────────────────────────────────────────────
// Сүрөт компрессия утилиттери
// ─────────────────────────────────────────────────────────────

/// Товар сүрөттөрү үчүн — жакшы сапат
/// Колдонуу: product card, product detail
/// Чыгуу: max 1024×1024px, JPEG 80%
Future<Uint8List> compressImage(
  Uint8List bytes, {
  int quality = 80,
  int maxWidth = 1024,
  int maxHeight = 1024,
}) async {
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxWidth,
    minHeight: maxHeight,
    quality: quality,
    format: CompressFormat.jpeg,
  );
  return result;
}

/// Чат сүрөттөрү үчүн — тез жүктөлсүн
/// Колдонуу: chat message bubble
/// Чыгуу: max 800×800px, JPEG 70%
Future<Uint8List> compressChatImage(Uint8List bytes) async {
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: 800,
    minHeight: 800,
    quality: 70,
    format: CompressFormat.jpeg,
  );
  return result;
}

/// Story сүрөттөрү үчүн — оригинал катышты сактайт (9:16 же 16:9)
/// Колдонуу: admin story upload
/// Чыгуу: max 1080×1920px, JPEG 85%, EXIF жок
Future<Uint8List> compressStoryImage(Uint8List bytes) async {
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: 1080,
    minHeight: 1920,
    quality: 85,
    keepExif: false,
    format: CompressFormat.jpeg,
  );
  return result;
}

// ─────────────────────────────────────────────────────────────
// Cloudinary утилиттери
// ─────────────────────────────────────────────────────────────

/// Cloudinary URL'ин thumbnail форматка айлантуу
/// Колдонуу: product_card, message_bubble
/// Мисал: toCloudinaryThumb(url, width: 400)
String toCloudinaryThumb(String url, {int width = 400}) {
  if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
    return url.replaceFirst(
      '/upload/',
      '/upload/w_$width,q_auto,f_auto/',
    );
  }
  return url;
}