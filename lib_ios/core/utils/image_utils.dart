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

/// Товар сүрөтүнө "DD Online" watermark кош — оң аст бурч, мандарин, 16px, фонсуз
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

    // Сүрөттүн өлчөмүнө жараша шрифт размерин масштабтайбыз
    // Базалык: 800px туурасы → 16px. Пропорционалдуу.
    final fontSize = (w / 800) * 16.0;
    final margin   = w * 0.018; // оң жана ылдыйкы четтен аралык

    // Текст өлчөмүн алдын ала биле алмайбыз, ошон үчүн максималдуу туурасын колдонобуз
    final maxTextWidth = w * 0.5;

    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign:  TextAlign.left,
      fontSize:   fontSize,
      fontWeight: FontWeight.w700,
    ))
      ..pushStyle(ui.TextStyle(
        color:         const ui.Color(0xCCFF8A00), // мандарин, 80% opacity
        fontSize:      fontSize,
        fontWeight:    FontWeight.w700,
        letterSpacing: 0.3,
        shadows: [
          ui.Shadow(
            color:  const ui.Color(0x88000000), // жеңил көлөкө — окуу оңой болсун
            offset: ui.Offset(0.5, 0.5),
            blurRadius: 1.5,
          ),
        ],
      ))
      ..addText('DD Online');

    final para = pb.build()
      ..layout(ui.ParagraphConstraints(width: maxTextWidth));

    // Оң аст бурчка: x = w - textWidth - margin, y = h - textHeight - margin
    final tx = w - para.longestLine - margin;
    final ty = h - para.height - margin;

    canvas.drawParagraph(para, ui.Offset(tx, ty));

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