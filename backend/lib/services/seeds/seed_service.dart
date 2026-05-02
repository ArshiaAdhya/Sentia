/// SEED SERVICE
/// Converts emotion into seed rewards
/// Example:
/// happy → +5 seeds
/// sad → +3 seeds
///
/// rewardUser()        — main daily reward: mood seeds + streak bonus, once per IST day
/// computeMoodSeeds()  — average seed value of initial and final mood
/// computeStreakBonus()— +20 seeds every 7th consecutive day
///
/// Queries journal_entries and users tables directly via SupabaseClient.

import 'package:supabase/supabase.dart';
import '../../models/user_model.dart';
import '../../models/seed_model.dart';
import '../../../utils/constants.dart';
import '../../../utils/helpers.dart';

class SeedService {
  final SupabaseClient _client;

  SeedService(this._client);

  // ── DB helpers ──────────────────────────────────────────────────────────

  Future<AppUser?> _getUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  Future<AppUser> _updateSeeds(
    String userId, {
    required int newSeeds,
    required DateTime lastSeedUpdate,
  }) async {
    final response = await _client
        .from('users')
        .update({
          'seeds': newSeeds < 0 ? 0 : newSeeds,
          'last_seed_update': toDateString(lastSeedUpdate),
        })
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromJson(response);
  }

  // Reads initial_mood and final_mood from journal_entries for the given IST day.
  // IST is UTC+05:30, so IST 00:00 = UTC prev-day 18:30.
  Future<Map<String, dynamic>?> _getLatestJournalEntry(
    String userId,
    DateTime nowIst,
  ) async {
    final istMidnight = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final utcStart = istMidnight.subtract(const Duration(hours: 5, minutes: 30));
    final utcEnd = utcStart.add(const Duration(days: 1));

    return await _client
        .from('journal_entries')
        .select('initial_mood, final_mood')
        .eq('user_id', userId)
        .gte('created_at', utcStart.toIso8601String())
        .lt('created_at', utcEnd.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  // ── Business logic ───────────────────────────────────────────────────────

  int moodSeedValue(String mood) =>
      moodSeedValues[mood.toLowerCase()] ?? defaultMoodSeedValue;

  int computeMoodSeeds(String? initialMood, String? finalMood) {
    if (initialMood == null || finalMood == null) return 0;
    final a = moodSeedValue(initialMood);
    final b = moodSeedValue(finalMood);
    return ((a + b) / 2).floor();
  }

  int computeStreakBonus(int streak) {
    if (streak > 0 && streak % streakBonusInterval == 0) {
      return streakBonusAmount;
    }
    return 0;
  }

  bool _alreadyUpdatedToday(DateTime? lastSeedUpdate, DateTime nowUtc) {
    if (lastSeedUpdate == null) return false;
    return isSameIstDay(lastSeedUpdate, nowUtc);
  }

  Future<SeedRewardResult> rewardUser(String userId) async {
    final user = await _getUser(userId);
    if (user == null) throw Exception('User not found: $userId');

    final nowUtc = DateTime.now().toUtc();

    if (_alreadyUpdatedToday(user.lastSeedUpdate, nowUtc)) {
      return SeedRewardResult(
        earnedMoodSeeds: 0,
        streakBonus: 0,
        totalSeeds: user.seeds,
        alreadyUpdatedToday: true,
      );
    }

    final nowIst = toIst(nowUtc);
    final entry = await _getLatestJournalEntry(userId, nowIst);

    final moodSeeds = computeMoodSeeds(
      entry?['initial_mood'] as String?,
      entry?['final_mood'] as String?,
    );

    final bonus = computeStreakBonus(user.streak);
    final newSeeds = user.seeds + moodSeeds + bonus;
    final updated = await _updateSeeds(
      userId,
      newSeeds: newSeeds,
      lastSeedUpdate: nowUtc,
    );

    return SeedRewardResult(
      earnedMoodSeeds: moodSeeds,
      streakBonus: bonus,
      totalSeeds: updated.seeds,
      alreadyUpdatedToday: false,
    );
  }
}