import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Сүрөттөрдүн жалпы кэши (диск + RAM).
///
/// Демейки DefaultCacheManager 200 файлга чейин гана сактайт — базар
/// тиркемеси үчүн өтө аз: тизмени сыдырганда эле эски сүрөттөр өчүп,
/// кийин кайра интернеттен жүктөлөт. Бул менеджер 2000 сүрөттү 30 күнгө
/// чейин дискте сактайт, ошондуктан тиркемени кайра ачканда сүрөттөр
/// дароо (интернетсиз да) көрүнөт.
class DDImageCache {
  DDImageCache._();

  static const String key = 'ddImageCache';

  static final CacheManager manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
    ),
  );

  /// Оперативдик (RAM) кэшти чоңойтот — экрандар арасында өткөндө
  /// сүрөттөр кайра декоддолбой, дароо тартылат.
  static void configureMemoryCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 500;
    cache.maximumSizeBytes = 256 << 20; // 256 MB
  }
}
