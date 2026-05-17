import 'package:supabase/supabase.dart';
import '../../models/user_model.dart';

/// STREAK SERVICE
/// Tracks daily usage
/// Updates streak count
/// Provides streak bonus
class StreakService {
  final SupabaseClient supabase;

  StreakService(this.supabase);

  /// Called when a user sends a chat message. 
  /// Checks the last entry date and updates the streak accordingly.
  Future<AppUser> updateStreak(String userId) async {
    // 1. Fetch current user data
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
        
    final user = AppUser.fromJson(response);
    
    // 2. Calculate dates using UTC to avoid timezone issues
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    
    int newStreak = user.streak;
    
    if (user.lastEntryDate == null) {
      // First time chatting ever
      newStreak = 1;
    } else {
      final lastDate = user.lastEntryDate!.toUtc();
      final lastDay = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
      
      final difference = today.difference(lastDay).inDays;
      
      if (difference == 1) {
        // Chatted yesterday, streak continues!
        newStreak += 1;
      } else if (difference > 1) {
        // Missed a day, streak broken
        newStreak = 1;
      }
      // If difference == 0, they already chatted today, streak stays the same
    }
    
    // 3. Update the database
    await supabase.from('users').update({
      'streak': newStreak,
      'last_entry_date': now.toIso8601String(),
    }).eq('id', userId);
    
    user.streak = newStreak;
    user.lastEntryDate = now;
    
    return user;
  }
}