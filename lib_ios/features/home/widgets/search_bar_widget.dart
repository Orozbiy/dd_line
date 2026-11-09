import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/theme/dd_design.dart';
import '../../../core/app_localizations.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onChanged;
  final Function()? onClear;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;  // ← КОШ

  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _focusNode = FocusNode();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc         = AppLocalizations.of(context);
    final p           = DDPalette.of(context);
    final fillColor   = p.field;
    final borderColor = p.divider;

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,  // ← КОШ
      onChanged: widget.onChanged,
      // ── Тышка тийгенде клавиатура жабылат ── ← КОШ
      onTapOutside: (_) {
        _focusNode.unfocus();
      },
      style: AppTextStyles.bodyMedium.copyWith(
        color: p.text,
      ),
      decoration: InputDecoration(
        hintText: loc.get('search_hint'),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
        prefixIcon: Padding(padding: const EdgeInsets.all(10), child: Image.asset('assets/icons/nav/ic_search.png', width: 22, height: 22, color: const Color(0xFF6B7280))),
        suffixIcon: _controller.text.isNotEmpty
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controller.clear();
                  _focusNode.unfocus();  // ← KOШ: тазалагандан кийин жабылат
                  widget.onClear?.call();
                  widget.onChanged('');
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.cancel_rounded,
                      color: AppColors.grey400, size: 20),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
      ),
    );
  }
}