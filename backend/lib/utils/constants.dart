/// CONSTANTS
/// Stores:
/// - seed values
/// - flower costs
///
/// Maps each mood string to a seed reward value.
/// Streak bonus fires every 7 days (streakBonusInterval) and adds streakBonusAmount seeds.
/// Used by SeedService to compute daily rewards.
library;

const moodSeedValues = <String, int>{
  'happy': 15,
  'sad': 10,
  'anxious': 12,
  'reflective': 8,
  'neutral': 5,
};

const streakBonusAmount = 20;
const streakBonusInterval = 7;
const defaultMoodSeedValue = 5;
