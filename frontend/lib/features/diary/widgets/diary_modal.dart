import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../garden_state.dart';

class DiaryModal extends StatefulWidget {
  /// The date this diary entry belongs to.
  final DateTime date;

  const DiaryModal({super.key, required this.date});

  @override
  State<DiaryModal> createState() => _DiaryModalState();
}

class _DiaryModalState extends State<DiaryModal> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _saveEntry(BuildContext context) {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write something in your diary first! 🐧',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Trigger state update & rewards!
    final state = GardenState();
    state.addDiaryEntry(_textController.text);

    // Close the diary modal
    Navigator.of(context).pop();

    // Show a premium success reward dialog!
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DiaryRewardDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCF9), // Creamy white diary page color
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
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

              // Lined Paper Writing Area
              Flexible(
                child: Stack(
                  children: [
                    // Lined Paper Background Painter
                    Positioned.fill(
                      child: CustomPaint(
                        painter: LinedPaperPainter(),
                      ),
                    ),

                    // Cute flower outline sketch on bottom right
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Opacity(
                        opacity: 0.15,
                        child: Image.asset(
                          'assets/images/jasmine.png',
                          width: 48,
                          height: 48,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.local_florist_outlined,
                            size: 40,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ),

                    // Actual transparent TextField matching the lines
                    TextField(
                      controller: _textController,
                      maxLines: 8,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        height: 1.55, // Matches the line spacing of the painter!
                        color: const Color(0xFF2E3E32),
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: AppColors.primaryDark,
                      decoration: InputDecoration(
                        hintText: 'Today I felt...',
                        hintStyle: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          color: AppColors.textMedium.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                onPressed: () => _saveEntry(context),
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
                  'Save Entry',
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
  // Helper to format date as "MONDAY, 23 MAY 2025"
  String _formatDate(DateTime d) {
    const weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// Custom Painter to draw notebook horizontal lines
class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCDCD0) // Cozy faint grayish line color
      ..strokeWidth = 1.0;

    double lineSpacing = 28.0; // Line spacing matching the TextField style
    double startY = 28.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(size.width, startY),
        paint,
      );
      startY += lineSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// A beautiful glassmorphic modal popping up on reward
class DiaryRewardDialog extends StatelessWidget {
  const DiaryRewardDialog({super.key});

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
            // Floating Sparkly Success Icon
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
              'Entry Saved! 🌱',
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
            
            // Rewards Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRewardBadge('🌱 +20', 'Seeds Earned'),
                _buildRewardBadge('🔥 +1', 'Streak Day'),
                _buildRewardBadge('💎 +15', 'Points Gain'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Continue Button
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

  Widget _buildRewardBadge(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
