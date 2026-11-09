import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Товар сүрөттөрү үчүн компрессия
Future<Uint8List> compressImage(
  Uint8List bytes, {
  int quality = 75,
  int maxWidth = 800,
  int maxHeight = 800,
}) async {
  final result = await FlutterImageCompress.compressWithList(
    bytes,
    minWidth: maxWidth,
    minHeight: maxHeight,
    quality: quality,
    format: CompressFormat.jpeg,
    keepExif: false,
  );
  return result;
}

/// Чат сүрөттөрү үчүн
Future<Uint8List> compressChatImage(Uint8List bytes) async {
  return FlutterImageCompress.compressWithList(
    bytes,
    minWidth: 800,
    minHeight: 800,
    quality: 70,
    format: CompressFormat.jpeg,
  );
}

/// Story сүрөттөрү үчүн
Future<Uint8List> compressStoryImage(Uint8List bytes) async {
  return FlutterImageCompress.compressWithList(
    bytes,
    minWidth: 1080,
    minHeight: 1920,
    quality: 85,
    keepExif: false,
    format: CompressFormat.jpeg,
  );
}

// ─────────────────────────────────────────────────────────────
// WATERMARK — dart:ui, сервер жок
// ─────────────────────────────────────────────────────────────

/// Товар сүрөтүнө "DD Online" watermark кош — ылдыйкы оң бурч, 80% opacity, мандарин
Future<Uint8List> addWatermark(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final src   = frame.image;

  try {
    final w = src.width.toDouble();
    final h = src.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    canvas.drawImage(src, Offset.zero, Paint());

    // 80% opacity = 0xCC (255 * 0.8 ≈ 204 = 0xCC)
    const opacity    = 0xCC;
    // Капсула фону: кара (жарык/кара теманын суроту да норм болсун үчүн)
    const bgOpacity  = 0x99; // ~60% тунук кара фон

    // Размерлер сүрөттүн өлчөмүнө жараша
    final badgeH   = h * 0.09;           // badge бийиктиги
    final badgeW   = w * 0.40;           // badge туурасы
    final margin   = w * 0.025;          // четтен аралык
    final bx       = w - badgeW - margin; // он жак
    final by       = h - badgeH - margin; // ылдыйкы

    // Кара жарым-жарым фон капсула
    final bgPaint = Paint()
      ..color = ui.Color.fromARGB(bgOpacity, 0, 0, 0);
    final radius = badgeH / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, badgeW, badgeH),
        Radius.circular(radius),
      ),
      bgPaint,
    );

    // "D" чоң тамга — МАНДАРИН (#FF8A00)
    final dSize    = badgeH * 0.65;
    final dPb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign:  TextAlign.left,
      fontSize:   dSize,
      fontWeight: FontWeight.w900,
    ))
      ..pushStyle(ui.TextStyle(
        color:      ui.Color.fromARGB(opacity, 0xFF, 0x8A, 0x00), // мандарин
        fontSize:   dSize,
        fontWeight: FontWeight.w900,
      ))
      ..addText('D');
    final dPara = dPb.build()
      ..layout(ui.ParagraphConstraints(width: dSize * 1.2));
    canvas.drawParagraph(
      dPara,
      Offset(bx + badgeH * 0.18, by + (badgeH - dSize) / 2 - 1),
    );

    // "DD Online" текст — ак
    final txtSize = badgeH * 0.34;
    final txtPb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign:  TextAlign.left,
      fontSize:   txtSize,
      fontWeight: FontWeight.bold,
    ))
      ..pushStyle(ui.TextStyle(
        color:         ui.Color.fromARGB(opacity, 255, 255, 255), // ак
        fontSize:      txtSize,
        fontWeight:    FontWeight.bold,
        letterSpacing: 0.5,
      ))
      ..addText('DD Online');
    final txtPara = txtPb.build()
      ..layout(ui.ParagraphConstraints(width: badgeW * 0.7));
    canvas.drawParagraph(
      txtPara,
      Offset(bx + dSize * 1.0 + badgeH * 0.22, by + (badgeH - txtSize) / 2),
    );

    final picture  = recorder.endRecording();
    final finalImg = await picture.toImage(src.width, src.height);

    try {
      final byteData = await finalImg.toByteData(format: ui.ImageByteFormat.png);
      return FlutterImageCompress.compressWithList(
        byteData!.buffer.asUint8List(),
        minWidth:  src.width,
        minHeight: src.height,
        quality:   88,
        format:    CompressFormat.jpeg,
      );
    } finally {
      finalImg.dispose();
    }
  } finally {
    src.dispose();
  }
}

// Cloudinary URL thumbnail
String toCloudinaryThumb(String url, {int width = 400}) {
  if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
    return url.replaceFirst('/upload/', '/upload/w_$width,q_auto,f_auto/');
  }
  return url;
}