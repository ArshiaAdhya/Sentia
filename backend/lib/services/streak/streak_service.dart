import '../db/db_service.dart';
import '../../models/user_model.dart';

class StreakService {
  const StreakService(this.dbService);

  final DbService dbService;

  /// Assesses if a day has passed since last check-in to bump or reset the user's streak.
  Future<int> checkAndUpdateStreak(String userId) async {
    final user = await dbService.getUser(userId);
    if (user == null) return 0;

    final now = DateTime.now().toUtc();
    final lastCheckin = user.lastCheckin?.toUtc();
    
    int newStreak = user.streak;

    if (lastCheckin == null) {
      // First time check-in
      newStreak = 1;
    } else {
      // Check absolute calendar day difference
      final differenceInDays = DateTime(now.year, now.month, now.day).difference(
          DateTime(lastCheckin.year, lastCheckin.month, lastCheckin.day)).inDays;
      
      if (differenceInDays == 1) {
        newStreak += 1;
      } else if (differenceInDays > 1) {
        newStreak = 1; // Reset 
      }
      // if 0, streak stays the same 
    }

    // Award bonus seeds every 7 consecutive days
    if (newStreak > user.streak && newStreak % 7 == 0) {
      final currentSeeds = await dbService.getSeeds(userId);
      await dbService.updateSeeds(userId, currentSeeds.seeds + 10); // +10 Bonus Seeds
    }

    // Save updated info. 
    // We instantiate a new UserModel because the fields are final
    final updatedUser = UserModel(
      id: user.id,
      seeds: user.seeds, 
      lastCheckin: now,
      streak: newStreak,
      createdAt: user.createdAt,
      updatedAt: DateTime.now().toUtc(),
      lastEntryDate: user.lastEntryDate,
      lastSeedUpdate: user.lastSeedUpdate,
    );
    
    await dbService.updateUser(updatedUser);
    return newStreak;
  }
}
