import 'package:supabase/supabase.dart';

/// MOOD SERVICE
/// Stores daily emotion
/// Used for calendar visualization
class MoodService {

  MoodService(this.supabase);
  final SupabaseClient supabase;

  /// Saves or updates the user's emotion for the current day in the journal_entries table.
  /// If it's the first message of the day, it sets the initial_mood.
  /// Otherwise, it updates the final_mood.
  Future<void> saveDailyMood(String userId, String emotion) async {
    final now = DateTime.now().toUtc();
    
    // Determine the start and end of the current UTC day
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Find if there is already a journal entry for today
    final existingEntries = await supabase
        .from('journal_entries')
        .select('id')
        .eq('user_id', userId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);

    if (existingEntries.isNotEmpty) {
      // A journal entry exists for today! We update the final_mood to reflect 
      // the emotion from the most recent chat.
      final entryId = existingEntries.first['id'] as Object;
      
      await supabase.from('journal_entries').update({
        'final_mood': emotion,
        'updated_at': now.toIso8601String(),
      }).eq('id', entryId);
      
    } else {
      // First interaction of the day! We create a new journal entry.
      await supabase.from('journal_entries').insert({
        'user_id': userId,
        'initial_mood': emotion,
        'final_mood': emotion,
        'is_auto_saved': true,
        'summary_text': 'Started chatting...', // Temporary placeholder until full summary is generated
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }
}