import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../core/utils/review_manager.dart';
import '../../../core/supabase_client.dart';

/// Жылдыз оценка бөлүмү — комент жок, жылдыз гана
class ReviewSection extends StatefulWidget {
  final String productId;
  const ReviewSection({super.key, required this.productId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final _manager = ReviewManager.instance;
  int _myRating = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMyRating();
  }

  Future<void> _loadMyRating() async {
    final r = await _manager.getUserRating(widget.productId);
    if (mounted) {
      setState(() {
        _myRating = r ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _onStarTap(int star) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Оценка берүү үчүн кирүү керек!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _myRating = star;
      _isSaving = true;
    });

    await _manager.submitRating(
      productId: widget.productId,
      rating: star,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_starLabel(star)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _starLabel(int star) {
    switch (star) {
      case 1: return '⭐ Начар';
      case 2: return '⭐⭐ Болот';
      case 3: return '⭐⭐⭐ Жакшы';
      case 4: return '⭐⭐⭐⭐ Абдан жакшы';
      case 5: return '⭐⭐⭐⭐⭐ Мыкты!';
      default: return 'Оценка берилди';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _manager.getRatingStream(widget.productId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'avg': 0.0, 'count': 0};
        final avg = (data['avg'] as double?) ?? 0.0;
        final count = (data['count'] as int?) ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Жалпы рейтинг ──
              Row(
                children: [
                  // Чоң сан
                  Text(
                    avg > 0 ? avg.toStringAsFixed(1) : '—',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Жылдызчалар (окуу гана)
                      Row(
                        children: List.generate(5, (i) {
                          final filled = (i + 1) <= avg.round();
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count > 0 ? '$count адам баалады' : 'Азырынча баа жок',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.grey100),
              const SizedBox(height: 20),

              // ── Колдонуучунун баасы ──
              const Text('Сиздин бааңыз:', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final filled = star <= _myRating;
                    return GestureDetector(
                      onTap: _isSaving ? null : () => _onStarTap(star),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: filled ? Colors.amber : AppColors.grey300,
                          size: 44,
                        ),
                      ),
                    );
                  }),
                ),

              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

              if (_myRating > 0 && !_isSaving)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      _starLabel(_myRating),
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}