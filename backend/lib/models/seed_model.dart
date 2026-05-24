/// SEED MODEL
/// Stores total seeds of user
///
/// SeedRewardResult is returned by SeedService.rewardUser().
/// Contains earnedMoodSeeds, streakBonus, totalSeeds after the daily reward,
/// and alreadyUpdatedToday flag (true if user already claimed today's reward).
library;

class SeedRewardResult {

  const SeedRewardResult({
    required this.earnedMoodSeeds,
    required this.streakBonus,
    required this.totalSeeds,
    required this.alreadyUpdatedToday,
  });
  final int earnedMoodSeeds;
  final int streakBonus;
  final int totalSeeds;
  final bool alreadyUpdatedToday;

  Map<String, dynamic> toJson() => {
        'earnedMoodSeeds': earnedMoodSeeds,
        'streakBonus': streakBonus,
        'totalSeeds': totalSeeds,
        'alreadyUpdatedToday': alreadyUpdatedToday,
      };
}