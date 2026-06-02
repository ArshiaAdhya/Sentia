/// GARDEN MODEL
/// Represents planted flowers:
/// flower type, position
///
/// Maps the `user_garden_items` Supabase table.
/// itemId links to a flower in shop_catalog.
/// posX and posY are pixel coordinates from the top-left of the garden canvas.
library;

class PlantedFlower {
  PlantedFlower({
    this.id,
    required this.userId,
    required this.itemId,
    required this.posX,
    required this.posY,
    required this.plantedAt,
  });

  factory PlantedFlower.fromJson(Map<String, dynamic> json) {
    return PlantedFlower(
      id: json['id']?.toString(),
      userId: json['user_id'] as String,
      itemId: json['item_id'] as String,
      posX: (json['pos_x'] as num).toDouble(),
      posY: (json['pos_y'] as num).toDouble(),
      plantedAt: DateTime.parse(json['planted_at'] as String),
    );
  }
  final String? id;
  final String userId;
  final String itemId;
  final double posX;
  final double posY;
  final DateTime plantedAt;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'item_id': itemId,
        'pos_x': posX,
        'pos_y': posY,
        'planted_at': plantedAt.toIso8601String(),
      };
}
