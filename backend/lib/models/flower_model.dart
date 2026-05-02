// FLOWER MODEL
// Represents a row in shop_catalog table.
//
// Maps the `shop_catalog` Supabase table.
// Each Flower has a seed cost and an asset URL used by the frontend to render it.
// Only flowers where isActive = true are shown in the shop.

class Flower {
  final String id;
  final String displayName;
  final int seedCost;
  final String assetUrl;
  final bool isActive;

  Flower({
    required this.id,
    required this.displayName,
    required this.seedCost,
    required this.assetUrl,
    this.isActive = true,
  });

  factory Flower.fromJson(Map<String, dynamic> json) {
    return Flower(
      id: json['flower_id'] as String,
      displayName: json['display_name'] as String,
      seedCost: json['seed_cost'] as int,
      assetUrl: json['asset_url'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'flower_id': id,
        'display_name': displayName,
        'seed_cost': seedCost,
        'asset_url': assetUrl,
        'is_active': isActive,
      };
}
