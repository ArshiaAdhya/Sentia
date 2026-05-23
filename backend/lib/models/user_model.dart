class UserModel {
  UserModel({
    required this.id,
    required this.seeds,
    this.lastCheckin,
    required this.streak,
    required this.createdAt,
    required this.updatedAt,
    this.lastEntryDate,
    this.lastSeedUpdate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      seeds: json['seeds'] as int? ?? 0,
      lastCheckin: json['last_checkin'] != null 
          ? DateTime.parse(json['last_checkin'] as String) 
          : null,
      streak: json['streak'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
      lastEntryDate: json['last_entry_date'] != null 
          ? DateTime.parse(json['last_entry_date'] as String) 
          : null,
      lastSeedUpdate: json['last_seed_update'] != null 
          ? DateTime.parse(json['last_seed_update'] as String) 
          : null,
    );
  }

  final String id;
  final int seeds;
  final DateTime? lastCheckin;
  final int streak;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastEntryDate;
  final DateTime? lastSeedUpdate;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seeds': seeds,
      if (lastCheckin != null) 'last_checkin': lastCheckin!.toIso8601String(),
      'streak': streak,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (lastEntryDate != null) 'last_entry_date': lastEntryDate!.toIso8601String(),
      if (lastSeedUpdate != null) 'last_seed_update': lastSeedUpdate!.toIso8601String(),
    };
  }
}
