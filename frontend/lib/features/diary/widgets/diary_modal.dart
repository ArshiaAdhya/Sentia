import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../garden_state.dart';

class DiaryModal extends StatefulWidget {
  final DateTime date;

  const DiaryModal({super.key, required this.date});

  @override
  State<DiaryModal> createState() => _DiaryModalState();
}

class _DiaryModalState extends State<DiaryModal> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isFutureDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    return selectedDate.isAfter(today);
  }

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    try {
      final entry = await GardenState().getDiaryEntry(widget.date);
      if (mounted) _textController.text = entry;
    } catch (e) {
      debugPrint('Diary load failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEntry(BuildContext context) async {
    if (_isFutureDate) {
      _showSnackBar(context, 'Future dates are view-only.');
      return;
    }

    if (_textController.text.trim().isEmpty) {
      _showSnackBar(context, 'Please write something in your diary first! 🐧');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await GardenState().addDiaryEntry(
        widget.date,
        _textController.text,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (result.rewardAwarded) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => DiaryRewardDialog(result: result),
        );
      } else {
        _showSnackBar(context, 'Entry saved to your Mind Garden.');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, e.toString().replaceAll('Exception: ', ''));
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCF9),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dear Diary,',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(widget.date),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.textDark.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: CustomPaint(painter: LinedPaperPainter())),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Opacity(
                        opacity: 0.15,
                        child: Image.asset(
                          'assets/images/jasmine.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.local_florist_outlined,
                            size: 40,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _textController,
                      enabled: !_isLoading && !_isSaving && !_isFutureDate,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        height: 1.55,
                        color: const Color(0xFF2E3E32),
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: AppColors.primaryDark,
                      decoration: InputDecoration(
                        hintText: _isLoading
                            ? 'Opening your diary...'
                            : 'Today I felt...',
                        hintStyle: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          color: AppColors.textMedium.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(
                          top: 4,
                          left: 4,
                          right: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading || _isSaving || _isFutureDate
                    ? null
                    : () => _saveEntry(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primaryDark.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save Entry',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCDCD0)
      ..strokeWidth = 1;

    var startY = 28.0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(size.width, startY), paint);
      startY += 28;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiaryRewardDialog extends StatelessWidget {
  final DiarySaveResult result;

  const DiaryRewardDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF5EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryDark,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🌱 +${result.earnedSeeds} Seeds',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your thoughts have been safely cataloged in your Mind Garden.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE5EBE5), height: 1),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    'Seeds',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.oldSeeds} → ${result.newSeeds}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
