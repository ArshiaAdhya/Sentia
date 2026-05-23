import '../db/db_service.dart';

class MoodService {
  const MoodService(this.dbService);

  final DbService dbService;

  /// Saves a new daily mood evaluation into journal_entries
  Future<void> saveDailyMood({
    required String userId, 
    required String summary,
    String? initialMood,
    String? finalMood,
  }) async {
    await dbService.supabase.from('journal_entries').insert({
      'user_id': userId,
      'summary_text': summary,
      'initial_mood': initialMood,
      'final_mood': finalMood,
      'is_auto_saved': true,
    });
  }
  
  /// Retrieves the history of mood journal entries
  Future<List<Map<String, dynamic>>> getMoodHistory(String userId) async {
     final response = await dbService.supabase
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
        
     return List<Map<String, dynamic>>.from(response);
  }
}
