/// USER MODEL
/// Represents user data:
/// id, name, email
///
/// Lightweight typed mapper for a row in the `users` Supabase table.
/// All fields (seeds, streak, lastEntryDate, lastSeedUpdate) come directly
/// from the database — this class just gives them proper Dart types so we
/// can write user.seeds instead of user['seeds'] as int throughout the code.

class AppUser {
  final String id;
  int seeds;
  int streak;
  DateTime? lastEntryDate;
  DateTime? lastSeedUpdate;

  AppUser({
    required this.id,
    required this.seeds,
    required this.streak,
    this.lastEntryDate,
    this.lastSeedUpdate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      seeds: json['seeds'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastEntryDate: json['last_entry_date'] != null
          ? DateTime.parse(json['last_entry_date'] as String)
          : null,
      lastSeedUpdate: json['last_seed_update'] != null
          ? DateTime.parse(json['last_seed_update'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seeds': seeds,
        'streak': streak,
        'last_entry_date': lastEntryDate?.toIso8601String(),
        'last_seed_update': lastSeedUpdate?.toIso8601String(),
      };
}