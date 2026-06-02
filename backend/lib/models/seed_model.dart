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
    required this.oldSeeds,
    required this.newSeeds,
    this.mood,
  });
  final int earnedMoodSeeds;
  final int streakBonus;
  final int totalSeeds;
  final bool alreadyUpdatedToday;
  final int oldSeeds;
  final int newSeeds;
  final String? mood;

  bool get awarded => earnedMoodSeeds > 0 && !alreadyUpdatedToday;

  Map<String, dynamic> toJson() => {
        'earnedMoodSeeds': earnedMoodSeeds,
        'earnedSeeds': earnedMoodSeeds,
        'streakBonus': streakBonus,
        'totalSeeds': totalSeeds,
        'alreadyUpdatedToday': alreadyUpdatedToday,
        'oldSeeds': oldSeeds,
        'newSeeds': newSeeds,
        'mood': mood,
        'awarded': awarded,
      };
}
