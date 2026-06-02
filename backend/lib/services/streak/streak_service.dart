import 'package:backend/models/user_model.dart';
import 'package:backend/utils/helpers.dart';
import 'package:supabase/supabase.dart';

/// STREAK SERVICE
/// Tracks one completed conversation per IST calendar day.
class StreakService {
  StreakService(this.supabase);

  final SupabaseClient supabase;

  DateTime _istDay(DateTime utcDateTime) {
    final ist = toIst(utcDateTime);
    return DateTime(ist.year, ist.month, ist.day);
  }

  Future<AppUser> updateStreak(String userId) async {
    final response =
        await supabase.from('users').select().eq('id', userId).single();

    final user = AppUser.fromJson(response);
    final nowUtc = DateTime.now().toUtc();
    final today = _istDay(nowUtc);

    var newStreak = user.streak;

    if (user.lastEntryDate == null) {
      newStreak = 1;
    } else {
      final lastDay = _istDay(user.lastEntryDate!);
      final difference = today.difference(lastDay).inDays;

      if (difference == 1) {
        newStreak += 1;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    final updated = await supabase
        .from('users')
        .update({
          'streak': newStreak,
          'last_entry_date': nowUtc.toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromJson(updated);
  }
}
