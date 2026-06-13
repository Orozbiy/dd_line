import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

Future<Uint8List> compressImage(
  Uint8List bytes, {
  int quality = 75,
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