/// SEED SERVICE
/// Converts completed conversation mood into seed rewards.
library;

import 'dart:io';

import 'package:backend/models/seed_model.dart';
import 'package:backend/models/user_model.dart';
import 'package:backend/utils/constants.dart';
import 'package:supabase/supabase.dart';

class SeedService {
  SeedService(this._client);

  final SupabaseClient _client;

  Future<AppUser?> _getUser(String userId) async {
    final response =
        await _client.from('users').select().eq('id', userId).maybeSingle();

    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  Future<AppUser> _updateSeeds(
    String userId, {
    required int newSeeds,
    required DateTime rewardedAt,
  }) async {
    final response = await _client
        .from('users')
        .update({
          'seeds': newSeeds < 0 ? 0 : newSeeds,
          'last_seed_update': rewardedAt.toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromJson(response);
  }

  int moodSeedValue(String mood) {
    return moodSeedValues[mood.toLowerCase()] ?? defaultMoodSeedValue;
  }

  Future<SeedRewardResult> rewardCompletedConversation({
    required String userId,
    required String mood,
  }) async {
    final user = await _getUser(userId);
    if (user == null) throw Exception('User not found: $userId');

    final normalizedMood = mood.toLowerCase();
    final earnedSeeds = moodSeedValue(normalizedMood);
    final rewardedAt = DateTime.now().toUtc();
    final updated = await _updateSeeds(
      userId,
      newSeeds: user.seeds + earnedSeeds,
      rewardedAt: rewardedAt,
    );
    stdout.writeln(
      '[REWARD] oldSeeds=${user.seeds} reward=$earnedSeeds '
      'newSeeds=${updated.seeds} mood=$normalizedMood',
    );

    return SeedRewardResult(
      earnedMoodSeeds: earnedSeeds,
      streakBonus: 0,
      totalSeeds: updated.seeds,
      alreadyUpdatedToday: false,
      oldSeeds: user.seeds,
      newSeeds: updated.seeds,
      mood: normalizedMood,
    );
  }
}
