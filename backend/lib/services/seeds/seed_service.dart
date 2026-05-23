import '../db/db_service.dart';

class SeedService {
  const SeedService(this.dbService);

  final DbService dbService;

  /// Converts an emotion into a seed reward and updates the DB
  Future<int> awardSeedsForEmotion(String userId, String emotion) async {
    int reward = 0;
    final lowerEmotion = emotion.toLowerCase();
    
    // Emotion mapping logic
    if (lowerEmotion.contains('happy') || lowerEmotion.contains('joy')) {
      reward = 5;
    } else if (lowerEmotion.contains('sad') || lowerEmotion.contains('anxious')) {
      reward = 3;
    } else {
      reward = 1;
    }

    final currentSeeds = await dbService.getSeeds(userId);
    final newSeeds = currentSeeds.seeds + reward;
    await dbService.updateSeeds(userId, newSeeds);
    
    return reward;
  }
}
