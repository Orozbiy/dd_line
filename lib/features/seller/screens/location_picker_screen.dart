import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../services/seller_service.dart';
import '../../../core/supabase_client.dart';
class LocationPickerScreen extends StatefulWidget {
  final String shopName;
  final String sellerUid;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    required this.shopName,
    required this.sellerUid,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _service = SellerService();
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  bool _saving = false;
  bool _editMode = false;

  double? _savedLat;
  double? _savedLng;

  bool get _hasSaved => _savedLat != null && _savedLng != null;

  @override
  void initState() {
    super.initState();
    _savedLat = widget.initialLat;
    _savedLng = widget.initialLng;
    _latCtrl = TextEditingController(text: widget.initialLat?.toString() ?? '');
    _lngCtrl = TextEditingController(text: widget.initialLng?.toString() ?? '');
    _editMode = !_hasSaved;
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    return lat != null && lng != null &&
        lat >= -90 && lat <= 90 &&
        lng >= -180 && lng <= 180;
  }

  Future<void> _saveLocation() async {
    if (!_isValid) return;
    setState(() => _saving = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());

      await _service.updateLocation(uid, lat, lng);

      setState(() {
        _savedLat = lat;
        _savedLng = lng;
        _editMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Локация сакталды!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ката: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.black),
        ),
        title: Column(
          children: [
            Text(widget.shopName, style: AppTextStyles.headingSmall),
            Text('Дүкөндүн жайгашкан жери',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── САКТАЛГАН ЛОКАЦИЯ КАРТОЧКАСЫ ──
            if (_hasSaved) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Локация сакталган',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: const Color(0xFF16A34A))),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${_savedLat!.toStringAsFixed(6)}\nLng: ${_savedLng!.toStringAsFixed(6)}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── ФОРМА ──
            if (_editMode) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '1. Google Maps же Yandex Maps ач\n'
                  '2. Дүкөнүңдүн жерин тап\n'
                  '3. Картага узак бас → координаттар чыгат\n'
                  '4. Ошол сандарды бул жерге жаз',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600, height: 1.6),
                ),
              ),
              const SizedBox(height: 20),

              Text('Latitude', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey500)),
              const SizedBox(height: 8),
              TextField(
                controller: _latCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  hintText: '42.895300',
                  prefixIcon: const Icon(Icons.north, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              Text('Longitude', style: AppTextStyles.labelMedium.copyWith(color: const Color.fromARGB(255, 42, 66, 100))),
              const SizedBox(height: 8),
              TextField(
                controller: _lngCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  hintText: '74.597500',
                  prefixIcon: const Icon(Icons.east, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Spacer(),

              if (_hasSaved)
                TextButton(
                  onPressed: () => setState(() => _editMode = false),
                  child: Text('Жокко чыгаруу',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.grey500)),
                ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isValid && !_saving) ? _saveLocation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.grey200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('📍  Сактоо',
                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16)),
                ),
              ),
              SizedBox(height: bottomPad + 8),
            ],

            // ── ӨЗГӨРТҮҮ БАСКЫЧЫ (форма жок болгондо) ──
            if (!_editMode) ...[
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editMode = true),
                  icon: const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary),
                  label: Text('Локацияны өзгөртүү',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: bottomPad + 8),
            ],
          ],
        ),
      ),
    );
  }
}