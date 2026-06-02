import 'dart:io';

import 'package:backend/utils/helpers.dart';
import 'package:supabase/supabase.dart';

class ManualJournalSaveResult {
  const ManualJournalSaveResult({
    required this.entry,
    required this.rewardAwarded,
    required this.earnedSeeds,
    required this.oldSeeds,
    required this.newSeeds,
  });

  final Map<String, dynamic> entry;
  final bool rewardAwarded;
  final int earnedSeeds;
  final int oldSeeds;
  final int newSeeds;

  Map<String, dynamic> toJson() => {
        'entry': entry,
        'reward': {
          'awarded': rewardAwarded,
          'earnedSeeds': earnedSeeds,
          'oldSeeds': oldSeeds,
          'newSeeds': newSeeds,
        },
      };
}

class JournalValidationException implements Exception {
  const JournalValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JournalService {
  JournalService(this._client);

  final SupabaseClient _client;

  DateTime _parseDateString(String value) {
    final parts = value.split('-').map(int.parse).toList();
    if (parts.length != 3) {
      throw const JournalValidationException('Expected YYYY-MM-DD date.');
    }
    return DateTime(parts[0], parts[1], parts[2]);
  }

  DateTime _todayIstDate() {
    final nowIst = toIst(DateTime.now().toUtc());
    return DateTime(nowIst.year, nowIst.month, nowIst.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  _JournalDayWindow _dayWindow(DateTime istDate) {
    final utcStart = DateTime.utc(istDate.year, istDate.month, istDate.day)
        .subtract(const Duration(hours: 5, minutes: 30));
    return _JournalDayWindow(
      start: utcStart,
      end: utcStart.add(const Duration(days: 1)),
    );
  }

  DateTime _storedCreatedAtFor(DateTime istDate) {
    return DateTime.utc(istDate.year, istDate.month, istDate.day, 6, 30);
  }

  String? _dateStringFromCreatedAt(Object? createdAt) {
    if (createdAt == null) return null;

    DateTime parsed;
    if (createdAt is DateTime) {
      parsed = createdAt;
    } else {
      parsed = DateTime.parse(createdAt.toString());
    }

    final ist = toIst(parsed.toUtc());
    return toDateString(DateTime(ist.year, ist.month, ist.day));
  }

  Future<List<Map<String, dynamic>>> getEntriesForDate({
    required String userId,
    required DateTime date,
  }) async {
    final window = _dayWindow(date);
    final response = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .gte('created_at', window.start.toIso8601String())
        .lt('created_at', window.end.toIso8601String())
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<String>> getJournalDates(String userId) async {
    final response = await _client
        .from('journal_entries')
        .select('created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    final dates = <String>{};
    for (final entry in response) {
      final date = _dateStringFromCreatedAt(entry['created_at']);
      if (date != null) dates.add(date);
    }
    return dates.toList();
  }

  Future<ManualJournalSaveResult> saveManualEntry({
    required String userId,
    required String text,
    required String dateString,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw const JournalValidationException('Journal text cannot be empty.');
    }

    final date = _parseDateString(dateString);
    final today = _todayIstDate();
    if (date.isAfter(today)) {
      throw const JournalValidationException('Future dates cannot be written.');
    }

    final nowUtc = DateTime.now().toUtc();
    final entries = await getEntriesForDate(userId: userId, date: date);
    Map<String, dynamic>? manualEntry;
    for (final entry in entries) {
      if (entry['is_auto_saved'] == false) {
        manualEntry = entry;
        break;
      }
    }
    final alreadyManual = manualEntry != null;

    Map<String, dynamic> savedEntry;
    if (manualEntry != null) {
      final entryId = manualEntry['id'] as Object;
      final updated = await _client
          .from('journal_entries')
          .update({
            'summary_text': trimmedText,
            'is_auto_saved': false,
            'updated_at': nowUtc.toIso8601String(),
          })
          .eq('id', entryId)
          .select()
          .single();
      savedEntry = Map<String, dynamic>.from(updated);
    } else {
      final inserted = await _client
          .from('journal_entries')
          .insert({
            'user_id': userId,
            'summary_text': trimmedText,
            'is_auto_saved': false,
            'created_at': _storedCreatedAtFor(date).toIso8601String(),
            'updated_at': nowUtc.toIso8601String(),
          })
          .select()
          .single();
      savedEntry = Map<String, dynamic>.from(inserted);
    }

    final reward = await _maybeRewardManualEntry(
      userId: userId,
      shouldReward: !alreadyManual && _isSameDay(date, today),
    );

    return ManualJournalSaveResult(
      entry: savedEntry,
      rewardAwarded: reward.rewardAwarded,
      earnedSeeds: reward.earnedSeeds,
      oldSeeds: reward.oldSeeds,
      newSeeds: reward.newSeeds,
    );
  }

  Future<Map<String, dynamic>?> saveAutoSummary({
    required String userId,
    required String summary,
    required String mood,
  }) async {
    final trimmedSummary = summary.trim();
    if (trimmedSummary.isEmpty) return null;

    final date = _todayIstDate();
    final nowUtc = DateTime.now().toUtc();
    final entries = await getEntriesForDate(userId: userId, date: date);

    final hasManualEntry = entries.any(
      (entry) => entry['is_auto_saved'] == false,
    );
    if (hasManualEntry) return entries.isEmpty ? null : entries.first;

    Map<String, dynamic>? autoEntry;
    for (final entry in entries) {
      if (entry['is_auto_saved'] == true) {
        autoEntry = entry;
        break;
      }
    }

    if (autoEntry != null) {
      final updated = await _client
          .from('journal_entries')
          .update({
            'summary_text': trimmedSummary,
            'final_mood': mood,
            'updated_at': nowUtc.toIso8601String(),
          })
          .eq('id', autoEntry['id'] as Object)
          .select()
          .single();
      stdout.writeln(
        '[AUTO JOURNAL SAVED] date=${toDateString(date)} '
        'summary="$trimmedSummary"',
      );
      return Map<String, dynamic>.from(updated);
    }

    final inserted = await _client
        .from('journal_entries')
        .insert({
          'user_id': userId,
          'initial_mood': mood,
          'final_mood': mood,
          'is_auto_saved': true,
          'summary_text': trimmedSummary,
          'created_at': nowUtc.toIso8601String(),
          'updated_at': nowUtc.toIso8601String(),
        })
        .select()
        .single();
    stdout.writeln(
      '[AUTO JOURNAL SAVED] date=${toDateString(date)} '
      'summary="$trimmedSummary"',
    );

    return Map<String, dynamic>.from(inserted);
  }

  Future<_ManualReward> _maybeRewardManualEntry({
    required String userId,
    required bool shouldReward,
  }) async {
    final user = await _client
        .from('users')
        .select('seeds')
        .eq('id', userId)
        .maybeSingle();

    final oldSeeds = user?['seeds'] as int? ?? 0;

    if (!shouldReward || user == null) {
      return _ManualReward(
        rewardAwarded: false,
        earnedSeeds: 0,
        oldSeeds: oldSeeds,
        newSeeds: oldSeeds,
      );
    }

    final newSeeds = oldSeeds + 20;
    await _client.from('users').update({'seeds': newSeeds}).eq('id', userId);

    return _ManualReward(
      rewardAwarded: true,
      earnedSeeds: 20,
      oldSeeds: oldSeeds,
      newSeeds: newSeeds,
    );
  }
}

class _JournalDayWindow {
  const _JournalDayWindow({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

class _ManualReward {
  const _ManualReward({
    required this.rewardAwarded,
    required this.earnedSeeds,
    required this.oldSeeds,
    required this.newSeeds,
  });

  final bool rewardAwarded;
  final int earnedSeeds;
  final int oldSeeds;
  final int newSeeds;
}
