import 'package:flutter/material.dart';

/// Товарларды бөлүп-бөлүп жүктөөчү жардамчы (scroll-based pagination).
///
/// Алгач [pageSize] (25) товар жүктөлөт. Колдонуучу тизменин аягына
/// жакындаганда [loadMore] дагы 25 товарды Supabase'тан сурайт.
///
/// Колдонуу:
/// ```dart
/// late final _pager = PagedLoader<ProductModel>(
///   fetchPage: (from, to) async { ... .range(from, to) ... },
///   idOf: (p) => p.id,
/// );
/// _pager.refresh(_notify);          // биринчи бет / кайра жүктөө
/// _pager.loadMore(_notify);         // кийинки бет
/// ```
class PagedLoader<T> {
  PagedLoader({
    required this.fetchPage,
    this.idOf,
    this.pageSize = 25,
  });

  /// `from`..`to` (экөө тең кошо) аралыгындагы катарларды кайтарат —
  /// Supabase `.range(from, to)` менен дал келет.
  final Future<List<T>> Function(int from, int to) fetchPage;

  /// Кайталанган товарларды чыгарып салуу үчүн (беттер арасында жаңы
  /// товар кошулуп калса, бир эле товар эки жолу келиши мүмкүн).
  final Object? Function(T item)? idOf;

  final int pageSize;

  final List<T> items = [];

  /// Биринчи бет жүктөлүп жатат.
  bool isLoading = false;

  /// Кийинки бет жүктөлүп жатат.
  bool isLoadingMore = false;

  /// Серверде дагы товар бар.
  bool hasMore = true;

  /// Эң жок дегенде бир жолу жүктөлүп бүттү.
  bool loadedOnce = false;

  // Канча катар серверден алынды (кайталангандарды кошо) — кийинки
  // беттин башталышы.
  int _offset = 0;

  // Эски (кеч келген) жоопторду таштоо үчүн — мисалы издөө өзгөргөндө.
  int _generation = 0;

  final Set<Object?> _seen = {};

  /// Биринчи бетти (кайра) жүктөйт. Жаңы маалымат келгенче эски тизме
  /// экранда калат.
  Future<void> refresh(VoidCallback notify) async {
    final gen = ++_generation;
    isLoading = true;
    isLoadingMore = false;
    notify();
    try {
      final page = await fetchPage(0, pageSize - 1);
      if (gen != _generation) return;
      items.clear();
      _seen.clear();
      _offset = page.length;
      _append(page);
      hasMore = page.length >= pageSize;
    } catch (e) {
      debugPrint('❌ PagedLoader.refresh: $e');
    } finally {
      if (gen == _generation) {
        isLoading = false;
        loadedOnce = true;
        notify();
      }
    }
  }

  /// Кийинки 25 товарды кошот.
  Future<void> loadMore(VoidCallback notify) async {
    if (isLoading || isLoadingMore || !hasMore) return;
    final gen = _generation;
    isLoadingMore = true;
    notify();
    try {
      final page = await fetchPage(_offset, _offset + pageSize - 1);
      if (gen != _generation) return;
      _offset += page.length;
      _append(page);
      hasMore = page.length >= pageSize;
    } catch (e) {
      debugPrint('❌ PagedLoader.loadMore: $e');
    } finally {
      if (gen == _generation) {
        isLoadingMore = false;
        notify();
      }
    }
  }

  void _append(List<T> page) {
    final id = idOf;
    if (id == null) {
      items.addAll(page);
      return;
    }
    for (final item in page) {
      if (_seen.add(id(item))) items.add(item);
    }
  }

  /// Scroll аягына [threshold] px калганда `true` кайтарат.
  /// `NotificationListener<ScrollNotification>` ичинде колдонулат.
  static bool nearEnd(ScrollNotification n, {double threshold = 600}) {
    final m = n.metrics;
    return m.axis == Axis.vertical && m.extentAfter < threshold;
  }
}

/// ilike үчүн издөө сөзүн коопсуз кылат (`%`, `_` жана `\` белгилери).
String ilikePattern(String query) {
  final escaped = query
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '%$escaped%';
}

/// Тизменин аягындагы "дагы жүктөлүп жатат" индикатору.
class PagedFooter extends StatelessWidget {
  const PagedFooter({super.key, required this.visible, required this.color});

  final bool visible;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
        ),
      ),
    );
  }
}
