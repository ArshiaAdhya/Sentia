/// CONSTANTS
/// Stores:
/// - seed values
/// - flower costs
///
/// Maps each mood string to a seed reward value.
/// Streak bonus fires every 7 days (streakBonusInterval) and adds streakBonusAmount seeds.
/// Used by SeedService to compute daily rewards.

const moodSeedValues = <String, int>{
  'happy': 15,
  'sad': 3,
  'neutral': 7,
  'angry': 5,
  'stressed': 6,
  'calm': 10,
};

const streakBonusAmount = 20;
const streakBonusInterval = 7;
const defaultMoodSeedValue = 5;