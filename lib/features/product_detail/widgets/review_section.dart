import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/app_localizations.dart';
import '../../../core/utils/review_manager.dart';
import '../../../core/supabase_client.dart';

class ReviewSection extends StatefulWidget {
  final String productId;
  const ReviewSection({super.key, required this.productId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final _manager    = ReviewManager.instance;
  final _commentCtrl = TextEditingController();
  int   _myRating   = 0;
  String _myComment = '';
  bool  _isLoading  = true;
  bool  _isSaving   = false;
  bool  _showInput  = false;
  Map<String, dynamic>? _localOverride;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final row     = await _manager.getUserRatingAndComment(widget.productId);
    final reviews = await _manager.getReviews(widget.productId);
    if (mounted) {
      setState(() {
        _myRating   = (row?['rating'] as int?) ?? 0;
        _myComment  = (row?['comment'] as String?) ?? '';
        _commentCtrl.text = _myComment;
        _reviews    = reviews;
        _isLoading  = false;
      });
    }
  }

  Future<void> _onStarTap(int star) async {
    final loc  = AppLocalizations.of(context);
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.get('review_login_required')),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() { _myRating = star; _showInput = true; });
  }

  Future<void> _save() async {
    final loc  = AppLocalizations.of(context);
    final user = supabase.auth.currentUser;
    if (user == null || _myRating == 0) return;

    setState(() { _isSaving = true; });
    final comment = _commentCtrl.text.trim();
    await _manager.submitRating(
      productId: widget.productId,
      rating: _myRating,
      comment: comment.isNotEmpty ? comment : null,
    );
    if (mounted) {
      final fresh   = await _manager.fetchRatingData(widget.productId);
      final reviews = await _manager.getReviews(widget.productId);
      setState(() {
        _isSaving      = false;
        _myComment     = comment;
        _localOverride = fresh;
        _reviews       = reviews;
        _showInput     = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.get('review_submitted')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  String _starLabel(AppLocalizations loc, int star) {
    switch (star) {
      case 1: return loc.get('star_1');
      case 2: return loc.get('star_2');
      case 3: return loc.get('star_3');
      case 4: return loc.get('star_4');
      case 5: return loc.get('star_5');
      default: return loc.get('review_submitted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg      = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E45) : const Color(0xFFF0F0F0);
    final subColor    = isDark ? const Color(0xFF8888AA) : const Color(0xFFAAAAAA);
    final emptyColor  = isDark ? const Color(0xFF444466) : const Color(0xFFDDDDDD);
    final labelColor  = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final inputBg     = isDark ? const Color(0xFF252538) : const Color(0xFFF8F8F8);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _manager.getRatingStream(widget.productId),
      builder: (context, snapshot) {
        final data  = _localOverride ?? snapshot.data ?? {'avg': 0.0, 'count': 0};
        final avg   = (data['avg'] as double?) ?? 0.0;
        final count = (data['count'] as int?) ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Рейтинг карточка ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Жогорку сап
                  Row(
                    children: [
                      Column(
                        children: [
                          if (avg > 0) ...[
                            Text(avg.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.amber, height: 1)),
                            const SizedBox(height: 4),
                            Text('$count ${loc.get('review_count')}',
                                style: TextStyle(fontSize: 11, color: subColor)),
                          ] else ...[
                            Icon(Icons.star_outline_rounded, size: 36, color: subColor),
                            const SizedBox(height: 4),
                            Text(loc.get('review_no_ratings'),
                                style: TextStyle(fontSize: 11, color: subColor),
                                textAlign: TextAlign.center),
                          ],
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 44, color: borderColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) => Icon(
                                (i + 1) <= avg.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber, size: 16,
                              )),
                            ),
                            const SizedBox(height: 6),
                            Text(loc.get('your_rating'),
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w600, color: labelColor)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Колдонуучунун жылдыздары
                  if (_isLoading)
                    const SizedBox(height: 36,
                        child: Center(child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2)))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star   = i + 1;
                        final filled = star <= _myRating;
                        return GestureDetector(
                          onTap: _isSaving ? null : () => _onStarTap(star),
                          child: AnimatedScale(
                            scale: filled ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: filled ? Colors.amber : emptyColor,
                                size: 34,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                  // Тандалган баанын аты
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _myRating > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_starLabel(loc, _myRating),
                                  style: const TextStyle(fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber)),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Комментарий жазуу панели ──────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _showInput
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _commentCtrl,
                                  maxLines: 3,
                                  maxLength: 300,
                                  style: TextStyle(color: labelColor, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: loc.get('add_review'),
                                    hintStyle: TextStyle(color: subColor),
                                    filled: true,
                                    fillColor: inputBg,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary, width: 1.5),
                                    ),
                                    counterStyle: TextStyle(
                                        color: subColor, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Бир кнопка: Сактоо
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(width: 20, height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2))
                                        : Text(loc.get('save'),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // "Комментарий жазуу" баскычы (жылдыз тандалганда жашырылат)
                  if (!_showInput && _myRating > 0 && !_isSaving)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextButton.icon(
                        onPressed: () => setState(() { _showInput = true; }),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          _myComment.isNotEmpty
                              ? loc.get('edit_review')
                              : loc.get('add_review'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Пикирлер тизмеси ──────────────────────────────────────────
            if (_reviews.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(loc.get('reviews'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: labelColor)),
              const SizedBox(height: 10),
              ..._reviews.map((r) => _ReviewCard(
                    review: r,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    subColor: subColor,
                    labelColor: labelColor,
                  )),
            ],
          ],
        );
      },
    );
  }
}

// ── Пикир карточкасы ────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isDark;
  final Color cardBg, borderColor, subColor, labelColor;

  const _ReviewCard({
    required this.review,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.subColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final rating  = (review['rating'] as int?) ?? 0;
    final comment = (review['comment'] as String?) ?? '';
    final date    = review['created_at'] != null
        ? DateTime.tryParse(review['created_at'] as String)
        : null;
    final dateStr = date != null ? _fmtDate(date) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) => Icon(
                  (i + 1) <= rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber, size: 15,
                )),
              ),
              const Spacer(),
              Text(dateStr, style: TextStyle(fontSize: 11, color: subColor)),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment,
                style: TextStyle(fontSize: 13, color: labelColor, height: 1.4)),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Бүгүн';
    if (diff.inDays == 1) return 'Кечээ';
    if (diff.inDays < 7) return '${diff.inDays} күн мурун';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} жума мурун';
    return '${(diff.inDays / 30).floor()} ай мурун';
  }
}
