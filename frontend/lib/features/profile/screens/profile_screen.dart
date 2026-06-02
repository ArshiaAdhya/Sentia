import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../services/api_service.dart';
import '../../auth/screens/auth_screen.dart';
import '../../diary/widgets/diary_modal.dart';
import '../../garden_state.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onGoToShop;

  const ProfileScreen({
    super.key,
    required this.onGoToShop,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Currently displayed month/year in the calendar
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
  }

  // Open the diary for a specific date
  void _openDiaryForDate(BuildContext context, DateTime date) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DiaryModal(date: date),
    );
  }

  void _prevMonth() {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1);
    });
  }

  Future<void> _logout() async {
    try {
      await ApiService.post('/auth/logout', {});
    } catch (_) {
      // Local logout should still proceed if backend logout is unavailable.
    }

    await ApiService.clearAuthData();
    GardenState().resetState();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: GardenState(),
        builder: (context, child) {
          final state = GardenState();
          return Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/garden_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.creamBackground,
                  ),
                ),
              ),

              // Glassmorphic blur overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ),

              // Screen Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        'Sentia AI',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppStyles.glassCardDeco,
                        child: Column(
                          children: [
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Username
                            Text(
                              state.username,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),

                            // Joined date
                            Text(
                              'JOINED ${state.joinedYear}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMedium,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0x333B5E43), height: 1),
                            const SizedBox(height: 20),

                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('🔥 ${state.streak}', 'Streak',
                                    AppColors.streakOrange),
                                _buildStatItem('🌱 ${state.seeds}', 'Seeds',
                                    AppColors.seedsGreen),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Calendar Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.glassCardDeco,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Month navigation header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: _prevMonth,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark
                                          .withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 20,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  _monthLabel(_calendarMonth),
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _nextMonth,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark
                                          .withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Weekday labels
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                  .map((d) => SizedBox(
                                        width: 36,
                                        child: Text(
                                          d,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMedium,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),

                            // Calendar grid
                            _buildCalendarGrid(context, state.journalDates),

                            const SizedBox(height: 12),

                            // Legend hint
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Entry written  •  Tap any date to write',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Shop shortcut
                      GestureDetector(
                        onTap: widget.onGoToShop,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: AppStyles.glassPillDeco,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🌸  ',
                                  style: TextStyle(fontSize: 16)),
                              Text(
                                'Make your garden prettier!',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(
                            'Logout',
                            style:
                                GoogleFonts.outfit(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: BorderSide(
                              color: AppColors.primaryDark.withOpacity(0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Calendar grid ──────────────────────────────────────────────────────────
  Widget _buildCalendarGrid(BuildContext context, List<DateTime> journalDates) {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);
    // Sunday = 0 offset for our grid (DateTime.weekday: Mon=1 … Sun=7)
    final startOffset = firstDay.weekday % 7; // Sun=0, Mon=1 … Sat=6
    final today = DateTime.now();

    // Build a flat list of optional day cells
    final cells = <_DayCell>[];
    // Leading empty cells
    for (int i = 0; i < startOffset; i++) {
      cells.add(_DayCell(day: null, date: null));
    }
    // Actual day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_calendarMonth.year, _calendarMonth.month, d);
      cells.add(_DayCell(day: d, date: date));
    }
    // Trailing empties to complete the last row
    while (cells.length % 7 != 0) {
      cells.add(_DayCell(day: null, date: null));
    }

    final rows = <Widget>[];
    for (int r = 0; r < cells.length ~/ 7; r++) {
      final rowCells = cells.sublist(r * 7, r * 7 + 7);
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: rowCells.map((cell) {
            if (cell.day == null) {
              return const SizedBox(width: 36, height: 36);
            }

            final date = cell.date!;
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isFuture = date.isAfter(today);
            final hasEntry = journalDates.any((j) =>
                j.year == date.year &&
                j.month == date.month &&
                j.day == date.day);

            return GestureDetector(
              onTap: isFuture ? null : () => _openDiaryForDate(context, date),
              child: _DayTile(
                day: cell.day!,
                hasEntry: hasEntry,
                isToday: isToday,
                isFuture: isFuture,
              ),
            );
          }).toList(),
        ),
      );
      if (r < cells.length ~/ 7 - 1) rows.add(const SizedBox(height: 6));
    }

    return Column(children: rows);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String _monthLabel(DateTime d) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Widget _buildStatItem(String val, String label, Color accentColor) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Day cell data ────────────────────────────────────────────────────────────
class _DayCell {
  final int? day;
  final DateTime? date;
  _DayCell({required this.day, required this.date});
}

// ─── Individual day tile widget ───────────────────────────────────────────────
class _DayTile extends StatelessWidget {
  final int day;
  final bool hasEntry;
  final bool isToday;
  final bool isFuture;

  const _DayTile({
    required this.day,
    required this.hasEntry,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;
    BoxShape shape = BoxShape.rectangle;

    if (isToday) {
      bgColor = AppColors.primaryDark;
      textColor = Colors.white;
      border = null;
      shape = BoxShape.circle;
    } else if (hasEntry) {
      bgColor = const Color(0xFF537C5A);
      textColor = Colors.white;
      border = null;
    } else if (isFuture) {
      bgColor = Colors.transparent;
      textColor = AppColors.textMedium.withOpacity(0.35);
      border =
          Border.all(color: AppColors.textMedium.withOpacity(0.15), width: 1);
    } else {
      bgColor = const Color(0xFFE5EBE5);
      textColor = AppColors.textDark;
      border = null;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(8),
        border: border,
      ),
      child: Center(
        child: Text(
          '$day',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isToday || hasEntry ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
