import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Товар сүрөттөрү үчүн: 1024px, 80% — жакшы сапат
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

/// Чат сүрөттөрү үчүн: 800px, 70% — тез жүктөлсүн
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

/// Cloudinary URL'ин thumbnail'га айлантуу
/// product_card жана message_bubble үчүн
String toCloudinaryThumb(String url, {int width = 400}) {
  if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
    return url.replaceFirst(
      '/upload/',
      '/upload/w_$width,q_auto,f_auto/',
    );
  }
  return url;
}
