class SeedModel {
  SeedModel({
    required this.seeds,
  });

  factory SeedModel.fromJson(Map<String, dynamic> json) {
    return SeedModel(
      seeds: json['seeds'] as int? ?? 0,
    );
  }

  final int seeds;

  Map<String, dynamic> toJson() {
    return {
      'seeds': seeds,
    };
  }
}
