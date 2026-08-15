import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/supabase_client.dart';
import '../services/notification_service.dart';

class UpdateChecker {
  UpdateChecker._();

  static bool _isShowing = false;

  static Future<void> check(BuildContext context, String langCode) async {
    // ✅ ДАРОО флаг коюлат — эки жолу чакырылса да 2-си кирбейт
    if (_isShowing) return;
    _isShowing = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final data = await supabase
          .from('app_version')
          .select()
          .eq('id', 1)
          .single();

      final latestVersion = data['latest_version'] as String;
      final minVersion    = data['min_version'] as String;
      final storeUrl      = data['play_store_url'] as String;

      final isOutdated  = _isOlder(currentVersion, latestVersion);
      final isMandatory = _isOlder(currentVersion, minVersion);

      // Эски эмес болсо — флагды өчүр
      if (!isOutdated) {
        _isShowing = false;
        return;
      }

      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        _isShowing = false;
        return;
      }

      _showUpdateDialog(
        context:     ctx,
        langCode:    langCode,
        storeUrl:    storeUrl,
        isMandatory: isMandatory,
      );
    } catch (e) {
      _isShowing = false; // ← ката болсо да өчүр
      debugPrint('⚠️ UpdateChecker ката: $e');
    }
  }

  static bool _isOlder(String current, String target) {
    final c = current.split('.').map(int.parse).toList();
    final t = target.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final cv = i < c.length ? c[i] : 0;
      final tv = i < t.length ? t[i] : 0;
      if (cv < tv) return true;
      if (cv > tv) return false;
    }
    return false;
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required String langCode,
    required String storeUrl,
    required bool isMandatory,
  }) {
    final isKy = langCode == 'ky';

    final title     = isKy ? '🚀 Жаңыртуу бар!'    : '🚀 Доступно обновление!';
    final message   = isKy
        ? 'Колдонмонун жаңы версиясы чыкты.\nЖакшыраак иштеши үчүн жаңыртыңыз.'
        : 'Вышла новая версия приложения.\nОбновите для лучшей работы.';
    final updateBtn = isKy ? 'Жаңыртуу'    : 'Обновить';
    final laterBtn  = isKy ? 'Кийинчерээк' : 'Позже';

    showDialog(
      context:            context,
      barrierDismissible: !isMandatory,
      barrierColor:       Colors.black.withOpacity(0.30),
      builder: (_) => PopScope(
        canPop: !isMandatory,
        onPopInvokedWithResult: (didPop, __) {
          if (didPop) _isShowing = false;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Иконка ──
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Аталыш ──
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // ── Текст ──
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 14,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Баскычтар ──
                    Row(
                      children: [
                        if (!isMandatory) ...[
                          Expanded(
                            child: _GlassBtn(
                              label: laterBtn,
                              onTap: () {
                                _isShowing = false;
                                Navigator.pop(_);
                              },
                              isAccent: false,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _GlassBtn(
                            label: updateBtn,
                            onTap: () async {
                              final uri = Uri.parse(storeUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            isAccent: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// Айнек баскыч
// ══════════════════════════════════════════════════════
class _GlassBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const _GlassBtn({
    required this.label,
    required this.onTap,
    required this.isAccent,
  });

  @override
  State<_GlassBtn> createState() => _GlassBtnState();
}

class _GlassBtnState extends State<_GlassBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: widget.isAccent
                ? const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.isAccent ? null : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isAccent
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: widget.isAccent
                ? [
                    BoxShadow(
                      color: const Color(0xFFD97706).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isAccent
                    ? Colors.white
                    : Colors.white.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}