import 'package:supabase/supabase.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../models/garden_model.dart';
import '../../models/seed_model.dart';

class DbService {
  const DbService(this.supabase);

  final SupabaseClient supabase;

  // --- User ---
  
  /// Fetches a user by their ID
  Future<UserModel?> getUser(String userId) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Updates all fields of a user
  Future<void> updateUser(UserModel user) async {
    await supabase.from('users').update(user.toJson()).eq('id', user.id);
  }

  // --- Chat ---
  
  /// Saves a single chat message
  Future<void> saveMessage(MessageModel message) async {
    await supabase.from('chat_messages').insert(message.toJson());
  }

  /// Retrieves the chat history for a specific session
  Future<List<MessageModel>> getChatHistory(String sessionId) async {
    final response = await supabase
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
        
    return response.map<MessageModel>((e) => MessageModel.fromJson(e)).toList();
  }

  // --- Seeds ---
  
  /// Retrieves the total seeds for a user
  Future<SeedModel> getSeeds(String userId) async {
    final response = await supabase
        .from('users')
        .select('seeds')
        .eq('id', userId)
        .single();
        
    return SeedModel.fromJson(response);
  }

  /// Updates the seeds count for a user (can also use RPC if needed)
  Future<void> updateSeeds(String userId, int newSeeds) async {
    await supabase.from('users').update({'seeds': newSeeds}).eq('id', userId);
  }

  // --- Streak ---
  
  /// Retrieves the current streak count for a user
  Future<int> getStreak(String userId) async {
    final response = await supabase
        .from('users')
        .select('streak')
        .eq('id', userId)
        .single();
        
    return response['streak'] as int? ?? 0;
  }

  /// Updates the streak count for a user
  Future<void> updateStreak(String userId, int newStreak) async {
    await supabase.from('users').update({'streak': newStreak}).eq('id', userId);
  }

  // --- Garden ---
  
  /// Retrieves all garden items planted by a user
  Future<List<GardenModel>> fetchGarden(String userId) async {
    final response = await supabase
        .from('user_garden_items')
        .select()
        .eq('user_id', userId);
        
    return response.map<GardenModel>((e) => GardenModel.fromJson(e)).toList();
  }

  /// Saves a new item planted in the user's garden
  Future<void> saveGardenItem(GardenModel item) async {
    await supabase.from('user_garden_items').insert(item.toJson());
  }
}
